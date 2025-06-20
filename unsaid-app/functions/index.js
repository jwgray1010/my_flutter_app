import functions from "firebase-functions/v2/https";
import express from "express";
import OpenAI from "openai";
import 'dotenv/config';

const app = express();

const openai = new OpenAI({
  apiKey: "sk-...your-key-here...",
});

app.use(express.json());

app.post('/analyzeTone', async (req, res) => {
  const { message, sensitivity, tone } = req.body;

  const prompt = `
The user wrote: "${message}"

Tone filter: ${tone}
Sensitivity: ${sensitivity}

Based on this message and the above settings:
1. What is the emotional tone? (One word)
2. Suggest a gentler or more emotionally secure rewrite, using the selected tone and sensitivity.
3. Offer a short communication tip (based on relationship dynamics).

Return all three clearly labeled.
`;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [{ role: "user", content: prompt }],
    });
    res.status(200).send({ result: completion.choices[0].message.content });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

export const analyzeTone = functions.onRequest(app);

