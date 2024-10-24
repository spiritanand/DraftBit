import { json, pgTable, timestamp, varchar } from "drizzle-orm/pg-core";
import { Dimension } from "../src/validation/styleSchema";
import { relations } from "drizzle-orm";

export const margins = pgTable("margin", {
  id: varchar({ length: 255 }).primaryKey(),
  top: json().$type<Dimension>(),
  right: json().$type<Dimension>(),
  bottom: json().$type<Dimension>(),
  left: json().$type<Dimension>(),
});

export const paddings = pgTable("padding", {
  id: varchar({ length: 255 }).primaryKey(),
  top: json().$type<Dimension>(),
  right: json().$type<Dimension>(),
  bottom: json().$type<Dimension>(),
  left: json().$type<Dimension>(),
});

export const elementStyles = pgTable("element_style", {
  elementId: varchar({ length: 255 }).primaryKey(),
  marginId: varchar({ length: 255 })
    .references(() => margins.id)
    .notNull(),
  paddingId: varchar({ length: 255 })
    .references(() => paddings.id)
    .notNull(),
  createdAt: timestamp().defaultNow(),
});

export const elementStylesRelations = relations(elementStyles, ({ one }) => ({
  margin: one(margins, { fields: [elementStyles.marginId], references: [margins.id] }),
  padding: one(paddings, { fields: [elementStyles.paddingId], references: [paddings.id] }),
}));
