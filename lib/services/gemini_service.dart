import 'dart:convert';
import 'dart:io';
import '../models/product.dart';
import 'gemini_client.dart';

class GeminiService {
  /// Analyzes a product image using Google Gemini API to extract title, Hindi title, description, category, and price.
  static Future<Map<String, dynamic>> analyzeProductImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text": """
You are a product pricing expert for Indian local markets.

Look at the image carefully and identify what the item actually is.

Pricing instructions (CRITICAL):
- Evaluate the item strictly at Delhi local market / artisan bazaar / mandi rates in INR.
- Think about what a local shopkeeper or street vendor would charge, NOT international or e-commerce prices.
- Estimate a realistic lower bound and upper bound price range in INR.
- Set "estimated_price_inr" to the LOWER BOUND of that range (the cheapest realistic price).
- Examples: a basic clay pot = 80-150 INR (use 80), a hand-knit scarf = 200-400 INR (use 200), a plate of biryani = 120-250 INR (use 120), wooden toys = 60-200 INR (use 60).

Return ONLY a valid JSON object with these exact keys:
{
  "title_en": "accurate short English name",
  "title_hi": "accurate short Hindi name",
  "description": "2-3 sentence honest description",
  "category": "one of: Pottery, Textiles, Woodwork, Jewelry, Metalwork, Food, Other",
  "estimated_price_inr": 80
}

Rules:
- Be accurate about what the item is. If it is food, call it food. If it is a pot, call it a pot.
- Do NOT force items into "artisan handicraft" if they are clearly something else.
- Do NOT inflate prices. Think local Indian wholesale/street rates, not retail or export.
- Return only pure JSON, no markdown formatting.
"""
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ]
    };

    final response = await GeminiClient.generateContent(body);

    if (response.statusCode != 200) {
      throw Exception('Gemini error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No analysis returned by Gemini.');
    }

    final text = candidates[0]['content']['parts'][0]['text'] as String;

    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  /// Processes a voice recording containing edit instructions for an existing product.
  static Future<Map<String, dynamic>> processVoiceProductEdit({
    required File audioFile,
    required Product currentProduct,
  }) async {
    final bytes = await audioFile.readAsBytes();
    final base64Audio = base64Encode(bytes);

    final promptText = """
You are an AI assistant updating product catalog details for a local artisan on ONDC.
Listen carefully to the user's spoken voice instructions in this audio clip (which may be in Hindi, English, or Hinglish).
Compare the user's voice instructions with the current product details below:
- Current Title (EN): ${currentProduct.nameEn}
- Current Title (HI): ${currentProduct.nameHi}
- Current Price: ₹${currentProduct.priceInRupees}
- Current Description: ${currentProduct.description.isNotEmpty ? currentProduct.description : 'Handcrafted artisan product'}
- Current Category: ${currentProduct.category}

Instructions:
1. Identify any requested changes to price, title, or description from the audio.
2. If the user mentions a new price, update "price_in_rupees" with that integer (in INR).
3. If the user mentions changing the title or description, update "name_en", "name_hi", or "description".
4. If a field was NOT changed or mentioned in the audio, KEEP the current value.
5. Create a concise, natural confirmation message of what was changed in English ("summary_en") and Hindi ("summary_hi").
   Example: "Product price updated to ₹500" / "कीमत बदलकर ₹500 कर दी गई है"

Output STRICTLY valid JSON with no markdown code blocks, matching this schema:
{
  "name_en": "${currentProduct.nameEn}",
  "name_hi": "${currentProduct.nameHi}",
  "price_in_rupees": ${currentProduct.priceInRupees},
  "description": "${currentProduct.description}",
  "category": "${currentProduct.category}",
  "summary_en": "Product details updated",
  "summary_hi": "उत्पाद की जानकारी अपडेट कर दी गई है"
}
""";

    final body = {
      "contents": [
        {
          "parts": [
            {"text": promptText},
            {
              "inline_data": {
                "mime_type": "audio/aac",
                "data": base64Audio,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.2,
      }
    };

    final response = await GeminiClient.generateContent(body);

    if (response.statusCode != 200) {
      throw Exception('Gemini voice edit error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response returned by Gemini.');
    }

    final text = candidates[0]['content']['parts'][0]['text'] as String;
    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    return jsonDecode(cleaned) as Map<String, dynamic>;
  }
}
