import { z } from "zod";

const dimensionSchema = z.object({
  value: z.union([z.literal(""), z.coerce.number()]),
  metric: z.enum(["px", "%"]),
  state: z.enum(["default", "changed", "focused"]),
});
export type Dimension = z.infer<typeof dimensionSchema>;

export const styleSchema = z
  .object({
    elementId: z.string(),
    margin: z.object({
      top: dimensionSchema,
      right: dimensionSchema,
      bottom: dimensionSchema,
      left: dimensionSchema,
    }),
    padding: z.object({
      top: dimensionSchema,
      right: dimensionSchema,
      bottom: dimensionSchema,
      left: dimensionSchema,
    }),
  })
  .strict();

export type StyleData = z.infer<typeof styleSchema>;
