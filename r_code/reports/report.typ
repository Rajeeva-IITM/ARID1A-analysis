// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  authors: none,
  date: none,
  abstract: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(inset: 2em)[
      #text(weight: "bold", size: 1.5em)[#title]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[Abstract] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
#show: doc => article(
  title: [Report - 19-8-24],
  margin: (x: 1in,y: 1.25in,),
  paper: "a4",
  font: ("CMU Serif",),
  fontsize: 12pt,
  sectionnumbering: "1.1.1.",
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)


#show link: set text(fill: rgb(0, 0, 255))
#show link: underline
= Background
<background>
Two genes, ARID1A and STING, have been shown to affect the chemoresistance of cancer cells. ARID1A knockouts have been shown to be more sensitive to Volasertib treatment @Srinivas_2022ARID1A. Low STING expression has been shown to correlate with chemoresistance and poor survival rates. Dr.~Anand Jeyashekaran’s group has worked on these genes and they hypothesize that the activation of these genes creates a unique metabolic state in the cancer cell lines which in turn confer resistance to chemotherapy.

= Hypothesis
<hypothesis>
- There is a difference in metabolism between the wild-type cells and ARID1A knockouts
- This difference makes ARID1A knockouts to be more susceptible to Volasertib treatment

= Data availability
<data-availability>
== RNA sequencing
<rna-sequencing>
#emph[Note:] There was an error while downloading the RNASeq reads from the NUS data storage. Processed Transcripts per Million (TPM) data was instead downloaded from #link("https://www.ncbi.nlm.nih.gov/geo/download/?type=rnaseq_counts&acc=GSE193942&format=file&file=GSE193942_norm_counts_TPM_GRCh38.p13_NCBI.tsv.gz")[NCBI];. This data has been generated by NCBI using their built-in RNASeq analysis pipeline. Although this may not exactly represent the data used by the authors who submitted the data, it is a good starting point. The TPM data for the following conditions were available:

- Cell line: GES1
  - Wild Type
  - ARID1A Knockout
  - Wild Type with Volasertib treatment
  - ARID1A Knockout with Volasertib treatment
- Cell line: OVCAR3
  - Wild Type
  - ARID1A Knockout

== CRISPR knockout
<crispr-knockout>
In the same GEO Project, we have also the CRISPR screens. However this analysis is performed on MCF10 cancer cell line which does not have RNA sequencing information.

== Genome Scale Metabolic Model (GSMM)
<genome-scale-metabolic-model-gsmm>
Recon3D was the (GSMM) model from which the context specific models were built. This model contains 2248 genes, 5835 metabolites and 10600 reactions.

= Methodology
<methodology>
All codes are available #link("https://github.com/Rajeeva-IITM/ARID1A-analysis")[here];.

== Building context-specific models
<building-context-specific-models>
The expression data contained replicates of the different conditions. The replicates were averaged to obtain a single expression value per gene for a given condition. Context specific models were built using CobraToolBox @Heirendt_2019CobraToolBox. The thresholding algorithm used to convert the expression data to binary presence/absence data was LocalGini @localgini_pavan. Using this binary data and the Gene-Protein-Reaction (GPR) rules, the active genes were identified and their corresponding active reactions were extracted. But the resultant model may not be complete or consistent (having no blocked reactions). To overcome this, model extraction methods build the final context-specific model by adding a minimal set of reactions. Three main model extraction algorithms were chosen:

- GIMME @Becker_2008Gimme
- SprintCore (Unpublished work)
- INIT @Agren_2012init

The biomass maintenance reaction was set as a core reaction (this reaction will be an active) in each of the model. The reason behind this choice was that one of the hallmarks of cancer is unbridled growth. Therefore, the resultant model should also be able to grow well.

== Analysis
<analysis>
Firstly, the reactions that are differentially present between the different conditions were identified. Following this, Flux Enrichment Analysis (FEA) was performed to identify the reaction subsystems that are enriched in this set of reactions.

In the set of reactions that were common across all the cases, flux sampling was performed (OPTGP sampler) to understand the distribution of fluxes in the different conditions. Following this, differential reaction fluxes were identified based on two conditions:

- A Kolmogorov-Smirnov test to check for the difference in distributions. The FDR adjusted p-value must be less than 0.05

- The flux fold change @Nanda2021 must be higher than 0.82 (corresponds to a 10 fold difference)

#math.equation(block: true, numbering: "(1)", [ $ upright("Flux Fold Change of Reaction") = frac(S^(‾)_(upright("condition 1")) - S^(‾)_(upright("condition 2")), lr(|S^(‾)_(upright("condition 1")) + S^(‾)_(upright("condition 2"))|)) $ ])<eq-flux_fold_change>

where $S^(‾)$ refers to the mean flux through the particular reaction.

We focused on four main pairwise comparisons:

- GES1 wild type: with and without Volasertib treatment, to understand the effects of the drug treatment on the metabolism of the cell

- GES1 wild type and GES1 ARID1A knockout, to understand how the deletion of ARID1A changes the the cell metabolism

- GES1 ARID1A knockout: with and without Volasertib treatment, to understand how ARID1A knockouts become more susceptible to the drug.

- OVCAR3 wild type and ARID1A knockout, to understand how the deletion of ARID1A changes the the cell metabolism

#pagebreak()
= Results
<results>
== Results from Srinivas et al., 2022
<results-from-srinivas-et-al.-2022>
#figure([
#box(image("images/clipboard-592237684.png"))
], caption: figure.caption(
position: bottom, 
[
Growth of GES1 cell linem wild type and ARID1A knockouts on Volasertib treatment
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-ges1>


#figure([
#box(image("images/clipboard-4784197.png"))
], caption: figure.caption(
position: bottom, 
[
Tumor size of OVCAR3 cell line in 2 combinations - ARID1A knockout and Volasertib treatment
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-ovcar3>


Few observations:

- GES1 cell line: (@fig-ges1)
  - ARID1A knockout has poorer growth than wild type (0nM concentration)
  - Upon Volasertib treatment, ARID1A knockout cells are more vulnerable
  - Under low concentrations of Volasertib (1nM), wild type cell lines show little difference in growth
- OVCAR3 cell line: (@fig-ovcar3)
  - ARID1A knockout has better growth (larger tumor size) than wild type
  - ARID1A knockouts are more vulnerable to Volasertib treatment
  - Little difference in growth for wild type cell lines upon Volasertib treatment

This will be used as a baseline over which the built GSMM models will be evaluated.

== Growth Analysis
<growth-analysis>
=== GIMME models
<gimme-models>
#figure([
#box(image("report_files/figure-typst/fig-funcs-1.svg"))
], caption: figure.caption(
position: bottom, 
[
The optimal growth rate of the context-specific model built using GIMME. All the models have a very similar growth rate.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-funcs>


In @fig-funcs, we observe that models built by GIMME have a similar growth rate across the board. This is likely due to how GIMME works. GIMME adds the minimal number of reactions required to satisfy a metabolic function (which in this case, was growth). Therefore, in all models, reactions that support the growth must have been added by GIMME resulting in similar growths across the conditions. Due to these models not representing any growth differences observed in the experimental work, they were not used for further analysis.

#pagebreak()
=== INIT Models
<init-models>
#figure([
#box(image("report_files/figure-typst/fig-init-growth-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Growths of the INIT built models
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-init-growth>


INIT models have produced some strange results that are contrary to experimental observation: (@fig-init-growth)

- Wild type OVCAR3 cells grow better than ARID1A knockouts in the absence of Volasertib

- GES1 ARID1A knockouts grow better than wild type cells in the absence of Volasertib

- In the presence of Volasertib, GES1 ARID1A knockouts grow better than wild type which goes against the main findings of the paper

Due to these reasons, no further analysis was done with the INIT models.

#pagebreak()
=== SprintCore Models
<sprintcore-models>
#figure([
#box(image("report_files/figure-typst/fig-sprint-growth-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Growths of the SprintCore built models
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-sprint-growth>


In @fig-sprint-growth, we observe that the growth rates are lower than the GIMME models. Moreover, we are able to observe some differences in growth values. OVCAR3-wildtype seems to be the fastest growing model. One interesting observation is the GES1-ARID1A knockout treated with Volasertib appears to grow slower than the wildtype treated with Volasertib. This was one of the main findings of Srinivas et al., 2022, i.e.~ARID1A deficient cells are more vulnerable to Volasertib.

Observations:

- OVCAR3 wild type grows better than ARID1A KO contrary to experimental observation

- GES1 wild type grows better than ARID1A knockout in both presence and absence (very minute difference) of Volasertib

- GES1 ARID1A knockouts grow better without Volasertib

Due to SprintCore being more representative than GIMME or INIT models, further analysis were performed on these.

== Reaction Analysis
<reaction-analysis>
The reactions that were unique to the given conditions were identified. Following this, the differential reactions were identified for the common reactions using @eq-flux_fold_change. All reported subsystems are statistically significant.

=== GES1 wild type: with and without Volasertib treatment
<ges1-wild-type-with-and-without-volasertib-treatment>
#figure([
#box(image("report_files/figure-typst/fig-comparison1-active-1.svg"))
], caption: figure.caption(
position: bottom, 
[
We identified the reactions that were more active upon Volasertib treatment compared to the wild-type GES1 cells. The subsystems for which the reactions were enriched were then identified.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison1-active>


#strong[Observations];:

- In @fig-comparison1-active:
  - We observe that extracellular transport subsystem and exchange reactions are enriched for upregulated (higher flux compared to the control) reactions in the presence of Volasertib. This could imply that the cell is involved in pushing out the drug from the cell
  - And it appears that the energy required to carry out these reactions are provided by the nucleotide intercoversion and mitochondrial transport pathways. There is also a small group of drug metabolising reactions upregulated
- In @fig-comparison1-unique:
  - Recapitulating previous findings, mitochondrial transport reactions and exchange reactions are uniquely enriched in Volasertib treated GES1 cells (@fig-comparison1-unique-2)
  - Many pentose phosphate pathway reactions are unique to the Volasertib treated cells

#block[
#quarto_super(
kind: 
"quarto-float-fig"
, 
caption: 
[
Comparing the unique reactions for GES1: WT and WT with Volasertib
]
, 
label: 
<fig-comparison1-unique>
, 
position: 
bottom
, 
supplement: 
"Figure"
, 
subrefnumbering: 
"1a"
, 
subcapnumbering: 
"(a)"
, 
[
#grid(columns: 1, gutter: 2em,
  [
#block[
#figure([
#box(image("report_files/figure-typst/fig-comparison1-unique-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Enriched subsystems of reactions unique to wild type GES1
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison1-unique-1>


]
],
  [
#block[
#figure([
#box(image("report_files/figure-typst/fig-comparison1-unique-2.svg"))
], caption: figure.caption(
position: bottom, 
[
Enriched subsystems of reactions unique to wild type GES1 with Volasertib
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison1-unique-2>


]
],
)
]
)
]
#pagebreak()
=== GES1 wild type and GES1 ARID1A knockout
<ges1-wild-type-and-ges1-arid1a-knockout>
#block[
#quarto_super(
kind: 
"quarto-float-fig"
, 
caption: 
[
Comparing the unique reactions for GES1: WT and AIRD1A KO
]
, 
label: 
<fig-comparison2-unique>
, 
position: 
bottom
, 
supplement: 
"Figure"
, 
subrefnumbering: 
"1a"
, 
subcapnumbering: 
"(a)"
, 
[
#grid(columns: 1, gutter: 2em,
  [
#block[
#figure([
#box(image("report_files/figure-typst/fig-comparison2-unique-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Enriched subsystems of reactions unique to wild type GES1 w.r.t. the ARID1A KO
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison2-unique-1>


]
],
  [
#block[
#figure([
#box(image("report_files/figure-typst/fig-comparison2-unique-2.svg"))
], caption: figure.caption(
position: bottom, 
[
Enriched subsystems of reactions unique to ARID1A KNO w.r.t. wild type GES1
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison2-unique-2>


]
],
)
]
)
]
#figure([
#box(image("report_files/figure-typst/fig-comparison2-active-1.svg"))
], caption: figure.caption(
position: bottom, 
[
We identified the reactions that were more active in ARID1A knockouts compared to the wild-type GES1 cells. The subsystems for which the reactions were enriched were then identified.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison2-active>


#strong[Observations:]

- Drug metabolising and exchange reactions are more enriched in the wild-type compared to the ARID1A knockout, suggesting that the wild type can process the drug better (@fig-comparison2-unique)
- Vitamin B6 and Steroid metabolism reactions are present in fewer numbers in the ARID1A knockout
- Bile acid synthesis reactions are enriched but they are out of place because GES1 is a gastric epithelial cell line whereas bile acid is produced only in the liver

#pagebreak()
=== GES1 ARID1A knockout - with Volasertib
<ges1-arid1a-knockout---with-volasertib>
#block[
#quarto_super(
kind: 
"quarto-float-fig"
, 
caption: 
[
Comparing the unique reactions for GES1: ARID1A KO and ARID1A KO with Volasertib
]
, 
label: 
<fig-comparison3-unique>
, 
position: 
bottom
, 
supplement: 
"Figure"
, 
subrefnumbering: 
"1a"
, 
subcapnumbering: 
"(a)"
, 
[
#grid(columns: 1, gutter: 2em,
  [
#block[
#figure([
#box(image("report_files/figure-typst/fig-comparison3-unique-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Enriched subsystems of reactions unique to wild type ARID1A KO w.r.t. the ARID1A KO with Volasertib
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison3-unique-1>


]
],
  [
#block[
#figure([
#box(image("report_files/figure-typst/fig-comparison3-unique-2.svg"))
], caption: figure.caption(
position: bottom, 
[
Enriched subsystems of reactions unique to wild type ARID1A KO with Volasertib w.r.t. the ARID1A KO
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison3-unique-2>


]
],
)
]
)
]
#figure([
#box(image("report_files/figure-typst/fig-comparison3-active-1.svg"))
], caption: figure.caption(
position: bottom, 
[
We identified the reactions that were more active upon Volasertib treatment compared to the GES1 ARID1A knockouts cells. The subsystems for which the reactions were enriched were then identified.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison3-active>


#strong[Observations:]

- Exchange reactions are more prevalent in untreated ARID1A knockouts (@fig-comparison3-unique)
- Vitamin B6 metabolism reactions seem to be enriched in Volasertib treated ARID1A knockouts but they were not enriched in untreated knockouts (@fig-comparison2-unique-2, @fig-comparison3-unique-2).
- Nucleotide interconversion reactions are more active in Volasertib treated ARID1A knockouts (@fig-comparison3-active)

#pagebreak()
=== OVCAR3: WT and ARID1A KO
<ovcar3-wt-and-arid1a-ko>
#block[
#quarto_super(
kind: 
"quarto-float-fig"
, 
caption: 
[
Comparing the unique reactions for OVCAR3: WT and ARID1A KO
]
, 
label: 
<fig-comparison4-unique>
, 
position: 
bottom
, 
supplement: 
"Figure"
, 
subrefnumbering: 
"1a"
, 
subcapnumbering: 
"(a)"
, 
[
#grid(columns: 1, gutter: 2em,
  [
#block[
#figure([
#box(image("report_files/figure-typst/fig-comparison4-unique-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Enriched subsystems of reactions unique to wild type OVCAR3 w.r.t. the ARID1A KO
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison4-unique-1>


]
],
  [
#block[
#figure([
#box(image("report_files/figure-typst/fig-comparison4-unique-2.svg"))
], caption: figure.caption(
position: bottom, 
[
Enriched subsystems of reactions unique to wild type ARID1A KO w.r.t. the wild-type
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison4-unique-2>


]
],
)
]
)
]
#figure([
#box(image("report_files/figure-typst/fig-comparison4-active-1.svg"))
], caption: figure.caption(
position: bottom, 
[
We identified the reactions that were more active in ARID1A knockouts compared to the wild-type OVCAR3 cells. The subsystems for which the reactions were enriched were then identified.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comparison4-active>


#strong[Observations:]

- Sugar metabolism reactions are enriched in the wild type compared to ARID1A knockouts (@fig-comparison4-unique-1). This could explain the observation in @fig-sprint-growth where the wild type OVCAR3 grows better than the ARID1A knockout
- Conversely, nucleotide, lipid and amino acid metabolism reactions are more enriched in the ARID1A knockouts
- Interestingly keratan suphate degradation and aliphatic amino acid metabolism are more active in ARID1A knockouts compared to the wild-type OVCAR3 strains (@fig-comparison4-active)

= Discussion
<discussion>
We built and characterized GSMMs to understand the effect of Volasertib treatment with a special focus on ARID1A gene which had been previously implicated in decreasing the resistance to the drug. We observed that wild type cells have more reactions enriched for drug metabolism compared to the ARID1A knockouts. Nucleotide interconversion appears to be an important reaction that is often upregulated in the conditions examined.

There appear to be some artifacts in the built models. Especially the presence of reactions that do not occur naturally in these cells, for instance, bile acid synthesis (@fig-comparison3-unique, @fig-comparison2-unique-1) or blood group synthesis @fig-comparison2-unique-1. These have to be ironed out before better insights can be obtained.

== Future Directions
<future-directions>
- Better method to evaluate the context-specific models
- Consensus model building to create more representative models
- Analysing the metabolic tasks of the built models to obtain greater insights
- Modifying the code to be able to incorporate other -omics data

#set bibliography(style: "apa")

#bibliography("references.bib")

