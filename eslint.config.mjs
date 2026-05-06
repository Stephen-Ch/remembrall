import { dirname } from "path"
import { fileURLToPath } from "url"
import { FlatCompat } from "@eslint/eslintrc"

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const compat = new FlatCompat({
  baseDirectory: __dirname,
})

const eslintConfig = [
  ...compat.extends("next/core-web-vitals", "next/typescript"),
  {
    rules: {
      "no-restricted-imports": [
        "error",
        {
          paths: [
            {
              name: "@prisma/client",
              message:
                "Do not import PrismaClient directly. Use dbForUser() from lib/db.ts to ensure RLS enforcement.",
            },
          ],
        },
      ],
    },
  },
  {
    files: ["lib/db.ts"],
    rules: {
      "no-restricted-imports": "off",
    },
  },
]

export default eslintConfig
