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
  title: [Report - 31-7-23],
  margin: (x: 1in,y: 1.5in,),
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
Two genes, ARID1A and STING, have been shown to affect the chemoresistance of cancer cells. ARID1A knockouts have been shown to be more sensitive to Volasertib treatment (Srinivas et al., 2022). Low STING expression has been shown to correlate with chemoresistance and poor survival rates. Dr.~Anand Jeyashekaran’s group has worked on these genes and they hypothesize that the activation of these genes creates a unique metabolic state in the cancer cell lines which in turn confer resistance to chemotherapy.

= Hypothesis
<hypothesis>
= Tasks
<tasks>
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
The expression data contained replicates of the different conditions. The replicates were averaged to obtain a single expression value per gene for a given condition. Context specific models were built using CobraToolBox. The thresholding algorithm used to convert the expression data to binary presence/absence data was LocalGini. Using this binary data and the Gene-Protein-Reaction (GPR) rules, the active genes were identified and their corresponding active reactions were extracted. But the resultant model may not be complete or consistent (having no blocked reactions). To overcome this, model extraction methods build the final context-specific model by adding a minimal set of reactions. Three main model extraction algorithms were chosen:

- GIMME
- SprintCore
- INIT

The biomass maintenance reaction was set as a core reaction (this reaction will be an active) in each of the model. The reason behind this choice was that one of the hallmarks of cancer is unbridled growth.

== Analysis
<analysis>
Firstly, the reactions that are differentially present between the different conditions were identified. Following this, Flux Enrichment Analysis (FEA) was performed to identify the reaction subsystems that are enriched in this set of reactions.

= Results
<results>
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


In @fig-funcs, we observer that models built by GIMME have a similar growth rate across the board. This is likely due to how GIMME works. GIMME adds the minimal number of reactions required to satisfy a metabolic function (which in this case, was growth). Therefore, in all models, reactions that support the growth must have been added by GIMME resulting in similar growths across the conditions.

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


What nonsense is this. Need better method to evaluate model.
