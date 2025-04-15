// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/schedshare_web.ex",
    "../lib/schedshare_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
        // Text colors
        text: {
          primary: {
            light: "#18181B", // zinc-900
            dark: "#FFFFFF"
          },
          secondary: {
            light: "#71717A", // zinc-500
            dark: "#A1A1AA" // zinc-400
          },
          tertiary: {
            light: "#A1A1AA", // zinc-400
            dark: "#71717A" // zinc-500
          }
        },
        // Background colors
        background: {
          light: "#FFFFFF",
          dark: "#18181B" // zinc-900
        },
        surface: {
          light: "#FFFFFF",
          dark: "#27272A" // zinc-800
        },
        // Interactive elements
        interactive: {
          light: "#18181B", // zinc-900
          dark: "#FFFFFF",
          primary: {
            light: "#059669", // emerald-600
            dark: "#10B981" // emerald-500
          }
        },
        // Status colors
        status: {
          success: {
            light: "#065F46", // emerald-800
            dark: "#059669" // emerald-600
          },
          successBg: {
            light: "#D1FAE5", // emerald-100
            dark: "#064E3B" // emerald-900
          },
          error: {
            light: "#991B1B", // red-800
            dark: "#DC2626" // red-600
          },
          errorBg: {
            light: "#FEE2E2", // red-100
            dark: "#7F1D1D" // red-900
          }
        },
        // Border colors
        border: {
          light: "#E4E4E7", // zinc-200
          dark: "#3F3F46" // zinc-700
        }
      }
    },
  },
  darkMode: 'media',
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })
      matchComponents({
        "hero": ({ name, fullPath }) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, { values })
    })
  ]
}
