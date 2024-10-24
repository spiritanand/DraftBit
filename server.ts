import "dotenv/config";
import express from "express";
import cors from "cors";
import { styleSchema } from "./src/validation/styleSchema";
import { z } from "zod";
import { db } from "./db";
import { elementStyles, margins, paddings } from "./db/schema";
import { eq } from "drizzle-orm";
// Add your routes here
const setupApp = (): express.Application => {
  const app: express.Application = express();

  app.use(cors());

  app.use(express.json());

  app.get("/examples", async (_req, res) => {
    // const { rows } = await client.query(`SELECT * FROM example_table`);
    res.json([]);
  });

  app.get("/styles/margin/:elementId", async (req, res) => {
    const { elementId } = req.params;

    const styles = await db.select().from(margins).where(eq(margins.id, elementId));

    if (styles.length === 0) res.status(404).json({ error: "Margin not found" });

    res.json(styles[0]);
  });

  app.get("/styles/padding/:elementId", async (req, res) => {
    const { elementId } = req.params;

    const styles = await db.select().from(paddings).where(eq(paddings.id, elementId));

    if (styles.length === 0) res.status(404).json({ error: "Padding not found" });

    res.json(styles[0]);
  });

  app.post("/styles/update", async (req, res) => {
    try {
      const validatedData = styleSchema.parse(req.body);

      const elementId = validatedData.elementId;

      const styles = await db
        .select()
        .from(elementStyles)
        .where(eq(elementStyles.elementId, elementId));

      if (styles.length === 0) {
        await db.insert(margins).values({
          id: elementId,
          ...validatedData.margin,
        });
        await db.insert(paddings).values({
          id: elementId,
          ...validatedData.padding,
        });
        await db.insert(elementStyles).values({
          elementId,
          marginId: elementId,
          paddingId: elementId,
        });
      } else {
        const marginId = styles[0].marginId;
        const paddingId = styles[0].paddingId;

        await db
          .update(margins)
          .set({
            ...validatedData.margin,
          })
          .where(eq(margins.id, marginId));

        await db
          .update(paddings)
          .set({
            ...validatedData.padding,
          })
          .where(eq(paddings.id, paddingId));
      }

      res.json({ success: true });
    } catch (err) {
      if (err instanceof z.ZodError) {
        res.status(400).json({ error: err.errors });
      } else {
        res.status(500).json({ error: err.message });
      }
    }
  });

  return app;
};

const main = async () => {
  const app = setupApp();
  const port = parseInt(process.env.SERVER_PORT!);
  app.listen(port, () => {
    console.log(`Draftbit Coding Challenge is running at http://localhost:${port}/`);
  });
};

main();
