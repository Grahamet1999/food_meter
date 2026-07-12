const functions = require("firebase-functions/v1");
const {HttpsError} = functions.https;
const Anthropic = require("@anthropic-ai/sdk");

const RECIPE_SCHEMA = {
  type: "object",
  properties: {
    recipes: {
      type: "array",
      items: {
        type: "object",
        properties: {
          title: {type: "string"},
          usesExpiringItems: {type: "array", items: {type: "string"}},
          ingredientsUsed: {type: "array", items: {type: "string"}},
          ingredientsNeeded: {type: "array", items: {type: "string"}},
          instructions: {type: "string"},
        },
        required: [
          "title", "usesExpiringItems", "ingredientsUsed",
          "ingredientsNeeded", "instructions",
        ],
        additionalProperties: false,
      },
    },
  },
  required: ["recipes"],
  additionalProperties: false,
};

/**
 * Suggests recipes from the caller's pantry items, prioritizing items
 * expiring soonest. Expects `data.items` as an array of
 * `{name: string, daysUntilExpiration: number}`.
 */
exports.suggestRecipes = functions
  .runWith({secrets: ["ANTHROPIC_API_KEY"]})
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in to get recipe suggestions.");
    }

    const items = data?.items;
    if (!Array.isArray(items) || items.length === 0) {
      throw new HttpsError("invalid-argument", "items must be a non-empty array.");
    }
    if (items.length > 100) {
      throw new HttpsError("invalid-argument", "Too many items — please try again with fewer.");
    }
    for (const item of items) {
      if (typeof item?.name !== "string" || !item.name.trim()) {
        throw new HttpsError("invalid-argument", "Each item must have a non-empty name.");
      }
    }

    const ingredientList = items
      .map((item) => {
        const days = item.daysUntilExpiration;
        const expiryNote = typeof days === "number" ?
          ` (expires in ${days} day${days === 1 ? "" : "s"})` :
          "";
        return `- ${item.name}${expiryNote}`;
      })
      .join("\n");

    const client = new Anthropic({apiKey: process.env.ANTHROPIC_API_KEY});

    const response = await client.messages.create({
      model: "claude-haiku-4-5",
      max_tokens: 1536,
      system: "You are a home cooking assistant. Suggest simple, realistic " +
      "recipes using the given pantry ingredients, prioritizing recipes " +
      "that use items expiring soonest so nothing goes to waste. Assume " +
      "common staples (salt, pepper, cooking oil, water) are available " +
      "even if not listed. Only suggest recipes that are genuinely " +
      "cookable with the given ingredients plus common staples.",
      messages: [{
        role: "user",
        content: `Here is what's in my pantry:\n${ingredientList}\n\n` +
        "Suggest 3-5 recipes I could make, prioritizing ones that use " +
        "the items expiring soonest.",
      }],
      output_config: {
        format: {
          type: "json_schema",
          schema: RECIPE_SCHEMA,
        },
      },
    });

    const textBlock = response.content.find((block) => block.type === "text");
    if (!textBlock) {
      throw new HttpsError("internal", "No recipe suggestions were returned.");
    }

    return JSON.parse(textBlock.text);
  });
