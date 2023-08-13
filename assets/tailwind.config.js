// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")



/*
textColor
borderColor
width
height
padding
margin
opacity
ring
rotate
scale
backgroundColor
borderWidth
borderRadius
fontSize
fontWeight
lineHeight
letterSpacing
fill
stroke
flex
grid
order
zIndex
visibility
space
divideWidth
divideColor
divideOpacity
divideStyle
backdropBlur
backdropBrightness
backdropContrast
backdropGrayscale
backdropInvert
backdropOpacity
backdropSaturate
backdropSepia
blur
brightness
contrast
grayscale
invert
saturate
sepia
skew
transitionProperty
transitionTimingFunction
transitionDuration
transitionDelay

 */
let extensions = [
  'textColor',
  'borderColor',
  'width',
  'height',
  'padding',
  'margin',
  'opacity',
  'ring',
  'rotate',
  'scale',
  'backgroundColor',
  'borderWidth',
  'borderRadius',
  'fontSize',
  'fontWeight',
  'lineHeight',
  'letterSpacing',
  'fill',
  'stroke',
  'flex',
  'grid',
  'order',
  'zIndex',
  'visibility',
  'space',
  'divideWidth',
  'divideColor',
  'divideOpacity',
  'divideStyle',
  'backdropBlur',
  'backdropBrightness',
  'backdropContrast',
  'backdropGrayscale',
  'backdropInvert',
  'backdropOpacity',
  'backdropSaturate',
  'backdropSepia',
  'blur',
  'brightness',
  'contrast',
  'grayscale',
  'invert',
  'saturate',
  'sepia',
  'skew',
  'transitionProperty',
  'transitionTimingFunction',
  'transitionDuration',
  'transitionDelay'
];

let extend = {};
extensions.forEach((extension) => {
  extend[extension] = ['html-scrollable-content', 'container-scrollable-content', 'html-scrollable-content-top', 'container-scrollable-content-top'];
});


module.exports = {
  variants: {
    extend: extend
  },
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
    "./src/**/*.{html,js}",
    "./node_modules/tw-elements/dist/js/**/*.js"
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require('@tailwindcss/typography'),
    require('tw-elements/dist/plugin.cjs'),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //

    function ({ addVariant, e }) {
      addVariant('scrollable-content', ({ modifySelectors, separator }) => {
        modifySelectors(({ className }) => {
          return `.scrollable-content .${e(`scrollable-content${separator}${className}`)}`;
        });
      });
    },
    plugin(({addVariant}) => addVariant("html-scrollable-content", ["html.scrollable-content&", "html.scrollable-content &"])),
    plugin(({addVariant}) => addVariant("container-scrollable-content", [".container.scrollable-content&", ".container.scrollable-content &"])),
    plugin(({addVariant}) => addVariant("html-scrollable-content-top", ["html.scrollable-content-top&", "html.scrollable-content-top &"])),
    plugin(({addVariant}) => addVariant("container-scrollable-content-top", [".container.scrollable-content-top&", ".container.scrollable-content-top &"])),
    plugin(({addVariant}) => addVariant("scrollablez", ["html.scrollable-content&", "html.scrollable-content &"])),


    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Hero Icons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": theme("spacing.5"),
            "height": theme("spacing.5")
          }
        }
      }, {values})
    })
  ]
}
