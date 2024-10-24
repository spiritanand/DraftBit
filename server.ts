import "dotenv/config";
import { Client } from "pg";
// import { backOff } from "exponential-backoff";
import express from "express";
import waitOn from "wait-on";
import onExit from "signal-exit";
import cors from "cors";
import { db } from "./db";

// Add your routes here
const setupApp = (): express.Application => {
  const app: express.Application = express();

  app.use(cors());

  app.use(express.json());

  app.get("/examples", async (_req, res) => {
    // const { rows } = await client.query(`SELECT * FROM example_table`);
    res.json([]);
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
