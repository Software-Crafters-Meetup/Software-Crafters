#import "@preview/codetastic:0.2.2": qrcode

#let c0 = rgb("#D72964")
#let c1 = rgb("#8C195F")
#let c2 = rgb("#000000")
#let c3 = rgb("#FFFFFF")

#let format = if "format" in sys.inputs { sys.inputs.format } else { "display" }
#let dimensions = if format == "display" {
  (
    margin: (x: 100pt, bottom: 178pt, top: 228pt),
    size: (width: 1080pt, height: 1920pt),
    toppad: 680pt,
    text: (20pt, 24pt, 32pt, 42pt, 60pt, 96pt),
  )
} else if format == "a4" {
  (
    margin: (x: 2.5cm, bottom: 2.5cm, top: 2.5cm),
    size: (width: 21cm, height: 29.7cm),
    toppad: 10cm,
    text: (10pt, 12pt, 16pt, 24pt, 32pt, 42pt),
  )
}

#let footer-logo = align(right, image(
  "./img/logo.svg",
  width: dimensions.margin.top,
))

#let lrbox = (cont, swap: false, small: false, fill: c0) => {
  let dim = (auto, 1fr)
  box(
    width: 100%,
    fill: fill,
    radius: dimensions.text.at(0),
    inset: if small {
      (
        y: dimensions.text.at(0) / 2,
        x: dimensions.text.at(4),
      )
    } else { dimensions.text.at(1) },
    grid(
      gutter: dimensions.text.at(4),
      columns: if swap { dim.rev() } else { dim },
      ..(if swap { cont.rev() } else { cont })
    ),
  )
}

#let qrbox = (title, data, small: true, swap: false) => {
  let small = if format == "a4" { true } else { small }
  set text(fill: c3)
  let cont = (
    align(horizon + center, box(
      fill: c3,
      qrcode(data, colors: (c3, c2), width: dimensions.margin.x, quiet-zone: 2),
      //   image(
      //   width: dimensions.margin.x, //100pt,
      //   height: dimensions.margin.x, //100pt,
      //   img,
      // )
    )),
    stack(
      dir: ttb,
      spacing: if small {
        dimensions.text.at(0) /*16pt*/
      } else { dimensions.text.at(2) },
      pad(
        top: dimensions.text.at(0) / 2, /*9pt*/
        text(size: dimensions.text.at(1), title),
      ),
      text(
        size: dimensions.text.at(0),
        data,
      ),
    ),
  )
  lrbox(cont, small: small, swap: swap)
}

#let title-layout(body) = {
  set page(
    margin: dimensions.margin,
    footer: footer-logo,
  )
  if format == "display" {
    set text(size: dimensions.text.at(3))
  }
  body
}

#let title-layout-preset(
  title,
  desc,
  date,
  meetup,
  day: "Do.",
  time: "18:00",
  extra: "",
) = title-layout[
  #let when = [
    === Wann?

    #day #date, #time
  ]
  #let where = [
    === Wo?

    OST RJ, Zimmer 1.262
  ]

  = Software Crafters

  == #title

  #v(1fr)

  #if format == "a4" {
    grid(
      columns: (1fr, 2fr),
      gutter: 1em,
      when, where,
    )
  } else {
    when
    v(0.5fr)
    where
  }


  === Was?

  #desc

  #v(0.5fr)
  ==== Wir bestellen Pizza ;)

  #extra

  #v(1fr)

  #qrbox(
    "Weitere Infos zum Meetup und der Themenwahl",
    "https://github.com/Software-Crafters-Meetup/Software-Crafters",
    swap: format == "a4",
  )

  #v(1fr)

]

#let normal-layout(
  img: "./img/IMG_6663_cropped.jpeg",
  dim: dimensions,
  body,
) = {
  set page(
    margin: (..dim.margin, top: dim.toppad),
    footer: footer-logo,
  )
  if img != none {
    place(dy: -dim.toppad, dx: -dim.margin.x, image(
      width: 100% + dim.margin.x * 2,
      height: dim.toppad,
      img,
    ))
  }
  // v(138pt)
  v(dim.margin.bottom - dim.margin.x / 2)
  body
}

#let flyer-layout = normal-layout.with(dim: (
  ..dimensions,
  margin: (x: 1.25cm, bottom: 1.25cm, top: 1.25cm),
))

#let normal-layout-preset = normal-layout[
  == Software Crafters
  #v(1fr)
  Wir treffen uns regelmässig um das *Handwerk der Softwareentwicklung* zu besprechen und zu praktizieren. Diese Treffen sind hands-on und praxisnah, ideal für Einsteiger:innen und Profis.
  #v(1fr)
  *Anfänger willkommen!*

  #v(1fr)

  ==== Organisiert von

  #grid(
    columns: 2,
    gutter: dimensions.text.at(4),
    box(radius: 50%, clip: true, image(
      height: 4em,
      width: 4em,
      "./img/moi.jpg",
    )),
    [
      Marco Kuoni \
      Student BSc Informatik \
      #link("mailto:marco.kuoni@ost.ch", "marco.kuoni@ost.ch")
    ],
  )

  #v(1fr)
]

#let image-layout(
  img: image(width: 100%, height: 100%, "./img/matrix.jpg"),
  overlay: none,
) = {
  set page(margin: 0pt)
  if overlay != none { place(center + horizon, overlay) }
  if img != none { img }
}

#let advert-layout(body) = {
  set page(
    ..dimensions.size,
    footer-descent: 0pt,
    header-ascent: 0pt,
  )
  set table(stroke: none)
  set text(size: dimensions.text.at(2), font: "Adelle Sans", fill: c2)
  show heading: set text(fill: c1)
  show heading.where(level: 1): set text(size: dimensions.text.at(5))
  show heading.where(level: 2): set text(size: dimensions.text.at(4))
  show heading.where(level: 3): set text(size: dimensions.text.at(3))
  show heading.where(level: 4): set text(size: dimensions.text.at(2))

  body
}
