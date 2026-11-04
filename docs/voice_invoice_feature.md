# Sesle Fatura Ekleme

Ses kaydı cihazda metne çevrilir, metin Supabase Edge Function'a gönderilir; fonksiyon
LLM ile müşteri/tedarikçi, ürünler ve ödeme türünü çıkarır, isimleri kullanıcının
veritabanı kayıtlarıyla eşleştirir ve fatura formuna uygulanacak bir taslak döndürür.
Fatura **otomatik kaydedilmez**; kullanıcı mevcut akışla (satış/alım → taraf → ürünler →
ödeme türü → kaydet) devam eder.

> Not: İstekte "TTS" denmiş olsa da buradaki dönüşüm konuşmadan metne (STT) çeviridir.
> Cihaz üzerinde `speech_to_text` ile canlı kısmi sonuçlar alınır; TTS (metinden sese)
> kullanılmaz.

## 1. Akış

```
Mikrofon FAB
  └─ speech_to_text (cihaz içi, ar-SA, kısmi sonuçlar)
       └─ canlı transkript
            └─ POST /functions/v1/voice-invoice  { transcript, type_hint }
                 ├─ JWT doğrula → user_id
                 ├─ customers / suppliers / products adaylarını çek (user_id filtreli)
                 ├─ OpenAI chat completions (json_object)
                 ├─ sunucu tarafı doğrulama + Arapça normalize/fuzzy eşleştirme
                 └─ taslak JSON: invoice_type, payment_type, party, items, warnings
                      └─ InvoiceCubit: tür → taraf → ürünler → ödeme türü
                           └─ kullanıcı kontrol eder ve mevcut "kaydet" akışını kullanır
```

## 2. Edge Function

Kod: [`supabase/functions/voice-invoice/index.ts`](../supabase/functions/voice-invoice/index.ts)

### Gerekli secret'lar

```bash
supabase secrets set OPENAI_API_KEY=sk-...
# İsteğe bağlı:
supabase secrets set OPENAI_MODEL=gpt-4o-mini
# OpenAI uyumlu başka bir sağlayıcı için:
supabase secrets set OPENAI_BASE_URL=https://api.openai.com/v1
```

### Dağıtım

```bash
supabase functions deploy voice-invoice
```

Varsayılan JWT doğrulaması açık kalmalıdır. Fonksiyon ayrıca gelen `Authorization`
başlığındaki kullanıcıyı `auth.getUser` ile doğrular ve tüm sorguları `user_id` ile
filtreler. `SUPABASE_SERVICE_ROLE_KEY` yalnızca sunucu tarafında kullanılır, istemciye
asla verilmez.

### İstek / yanıt

```http
POST /functions/v1/voice-invoice
Authorization: Bearer <kullanıcı erişim token'ı>
Content-Type: application/json

{
  "transcript": "بعت لسمير خبز خمسة كيلو ولبن كرتونتين على الحساب",
  "type_hint": "sale"
}
```

```json
{
  "transcript": "بعت لسمير خبز خمسة كيلو ولبن كرتونتين على الحساب",
  "invoice_type": "sale",
  "payment_type": "debt",
  "confidence": 0.92,
  "party": {
    "party_type": "customer",
    "id": "…",
    "name": "سمير",
    "phone": "09…",
    "matched": true
  },
  "items": [
    {
      "product_id": "…",
      "name": "خبز",
      "spoken_name": "خبز",
      "quantity": 5,
      "unit": "KG",
      "measurement": "5",
      "unit_price": 1200,
      "sale_price": 1200,
      "purchase_price": 900,
      "total_price": 6000,
      "matched": true
    }
  ],
  "unmatched_items": [{ "spoken_name": "لبن", "quantity": 2 }],
  "warnings": ["1 منتج لم يتم العثور عليه في المخزون"]
}
```

Hata yanıtları `{ "error": "..." }` biçimindedir: `400` geçersiz gövde, `401` oturum,
`413` uzun metin, `502` AI hatası, `500` yapılandırma/sorgu hatası.

### Davranış kuralları

- `invoice_type`: LLM çıkarımı; belirsizse `sale`.
- `payment_type`: `cash` veya `debt`; belirsizse `debt`.
- Parti yalnızca doğru listeden seçilir (`sale` → customers, `purchase` → suppliers).
- Ürün kimlikleri doğrulanır; bulunamayan ürünler `unmatched_items` olarak döner.
- Fiyatlar istemciden veya LLM'den alınmaz; `products.sale_price` / `purchase_price`.
- Aynı ürün birden çok kez söylenirse miktarlar toplanır.
- Miktarlar pozitif tam sayıya yuvarlanır (uygulamadaki `InvoiceItem.quantity` int'tir).

## 3. Flutter tarafı

| Katman | Dosya |
|---|---|
| Ayar nesnesi | `lib/features/voice_invoice/voice_invoice_config.dart` |
| Modeller | `lib/features/voice_invoice/data/models/voice_invoice_draft.dart` |
| Uzak veri kaynağı | `lib/features/voice_invoice/data/datasources/voice_invoice_remote_datasource.dart` |
| Repository | `lib/features/voice_invoice/data/repositories/voice_invoice_repository.dart` |
| Cihaz içi STT | `lib/features/voice_invoice/data/services/speech_recognition_service.dart` |
| Cubit + state | `lib/features/voice_invoice/presentation/bloc/` |
| Form uygulayıcı | `lib/features/voice_invoice/presentation/voice_invoice_applier.dart` |
| Sheet | `lib/features/voice_invoice/presentation/widgets/voice_invoice_sheet.dart` |
| FAB | `lib/features/invoices/presentation/pages/create_invoice_page.dart` |

`InvoiceCubit` mevcut API'siyle beslenir:

1. `setInvoiceType(draft.invoiceType)`
2. `setCustomer(id)` / `setSupplier(id)` (eşleşen taraf için)
3. Her eşleşen ürün için `addInvoiceItem(InvoiceItem(...))`
4. `setPaymentType(draft.paymentType)`

Eşleşmeyen taraf/ürünler formda boş bırakılır ve sheet'te uyarı olarak gösterilir;
kullanıcıdan manuel tamamlaması istenir.

### Android

`AndroidManifest.xml` içinde `RECORD_AUDIO` izni zaten var. Android 11+ için konuşma
tanıma servisini sorgulayan `<queries>` girdisi eklendi:

```xml
<intent>
  <action android:name="android.speech.RecognitionService"/>
</intent>
```

Cihazda Google konuşma tanıma servisi ve Arapça dil paketi yoksa STT çalışmaz;
sheet bu durumda anlaşılır bir hata gösterir.

## 4. Sınırlar

- Ses kaydı cihaz dışına gönderilmez; yalnızca metin edge function'a gider.
- Konuşma dili varsayılan olarak `ar_SA`; `VoiceInvoiceConfig.localeId` ile değiştirilebilir.
- Konuşma süresi ve sessizlik eşikleri de `VoiceInvoiceConfig` içindedir.
- LLM'e gönderilen aday listeleri 400'er satırla sınırlıdır; daha büyük kataloglarda
  fuzzy eşleştirme yalnızca bu ilk 400 kayıt içinde çalışır.
- Fonksiyonda hız sınırlama yoktur; üretimde gateway/plan bazlı limit önerilir.
- Ürün miktarı tam sayıdır; kesirli satış birimleri bu akışta desteklenmez.

## 5. Edge function tam kaynağı

Aşağıdaki kod, `supabase/functions/voice-invoice/index.ts` dosyasının birebir kopyasıdır;
repo kökünde `supabase functions deploy voice-invoice` ile doğrudan kullanılabilir.

```ts
// Supabase Edge Function: voice-invoice
// Turns a spoken invoice transcript into a structured, database-matched draft.
//
// Required secret: OPENAI_API_KEY
// Optional secrets: OPENAI_MODEL (default: gpt-4o-mini), OPENAI_BASE_URL
//
// The function never writes invoices. It only resolves names against the
// caller's rows and returns a draft that the app applies to the normal form.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MAX_TRANSCRIPT_LENGTH = 2000;
const CANDIDATE_LIMIT = 400;
const FUZZY_THRESHOLD = 0.55;

type InvoiceType = "sale" | "purchase";
type PaymentType = "cash" | "debt";

interface PartyRow {
  id: string;
  name: string;
  phone: string | null;
}

interface ProductRow {
  id: string;
  name: string;
  unit: string | null;
  measurement: string | null;
  sale_price: number | string | null;
  purchase_price: number | string | null;
}

interface LlmPlan {
  invoice_type?: string;
  payment_type?: string;
  confidence?: number;
  party?: {
    party_id?: string | null;
    spoken_name?: string | null;
  } | null;
  items?: Array<{
    product_id?: string | null;
    spoken_name?: string | null;
    quantity?: number | string | null;
  }>;
}

const SYSTEM_PROMPT = `أنت مساعد يحول نصاً منطوقاً بالعربية إلى مسودة فاتورة.
تستلم النص وقوائم العملاء والموردين والمنتجات الموجودة في قاعدة بيانات المتجر.
أعد JSON فقط بدون أي شرح، بالشكل التالي:
{
  "invoice_type": "sale" | "purchase",
  "payment_type": "cash" | "debt",
  "confidence": 0.0,
  "party": { "party_id": "id من القائمة أو null", "spoken_name": "الاسم كما قيل" },
  "items": [
    { "product_id": "id من القائمة أو null", "spoken_name": "اسم المنتج كما قيل", "quantity": 1 }
  ]
}
قواعد إلزامية:
1. اختر party_id فقط من قائمة customers عندما يكون النوع sale، ومن قائمة suppliers عندما يكون النوع purchase. لا تخترع معرفات أبداً.
2. اختر product_id فقط من قائمة products. إن لم تجد المنتج اتركه null واكتب الاسم المنطوق.
3. invoice_type: sale عند البيع (بعت، بعتت، باع، فاتورة بيع) وpurchase عند الشراء (اشتريت، جبت، أخذت، فاتورة شراء). إن كان غامضاً استخدم "sale".
4. payment_type: cash عند (نقدي، كاش، دفع الآن، سدد) وdebt عند (دين، باقي، آجل، على الحساب). إن كان غامضاً استخدم "debt".
5. الكمية عدد صحيح موجب. إن لم تُذكر استخدم 1. لا تكرر المنتج نفسه، اجمع الكميات.
6. لا تضف حقولاً غير مطلوبة ولا أسعاراً؛ الأسعار تأتي من قاعدة البيانات.
7. confidence رقم بين 0 و1 يعبر عن ثقتك العامة بالتحليل.`;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

function normalizeArabic(value: string): string {
  return value
    .toLowerCase()
    .replace(/[\u064B-\u065F\u0670\u0640]/g, "")
    .replace(/[أإآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function similarity(left: string, right: string): number {
  const a = normalizeArabic(left);
  const b = normalizeArabic(right);
  if (!a || !b) return 0;
  if (a === b) return 1;
  if (a.includes(b) || b.includes(a)) return 0.85;

  const aTokens = new Set(a.split(" "));
  const bTokens = new Set(b.split(" "));
  let shared = 0;
  for (const token of aTokens) {
    if (bTokens.has(token)) shared += 1;
  }
  const union = new Set([...aTokens, ...bTokens]).size;
  return union === 0 ? 0 : shared / union;
}

function bestMatch<T extends { name: string }>(
  spoken: string | null | undefined,
  rows: T[],
): T | null {
  const query = (spoken ?? "").trim();
  if (!query) return null;

  let best: T | null = null;
  let bestScore = 0;
  for (const row of rows) {
    const score = similarity(query, row.name);
    if (score > bestScore) {
      best = row;
      bestScore = score;
    }
  }
  return bestScore >= FUZZY_THRESHOLD ? best : null;
}

function toNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number.parseFloat(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return 0;
}

function toQuantity(value: unknown): number {
  const parsed = Math.round(toNumber(value));
  return parsed > 0 ? parsed : 1;
}

function stripCodeFence(content: string): string {
  const trimmed = content.trim();
  if (!trimmed.startsWith("```")) return trimmed;
  return trimmed
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/```$/i, "")
    .trim();
}

async function askModel(
  transcript: string,
  candidates: {
    customers: PartyRow[];
    suppliers: PartyRow[];
    products: ProductRow[];
  },
): Promise<LlmPlan> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    throw new HttpError(500, "إعداد خدمة الذكاء الاصطناعي غير مكتمل");
  }

  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";
  const baseUrl = (
    Deno.env.get("OPENAI_BASE_URL") ?? "https://api.openai.com/v1"
  ).replace(/\/$/, "");

  const candidatePayload = {
    customers: candidates.customers.map((row) => ({
      id: row.id,
      name: row.name,
      phone: row.phone,
    })),
    suppliers: candidates.suppliers.map((row) => ({
      id: row.id,
      name: row.name,
      phone: row.phone,
    })),
    products: candidates.products.map((row) => ({
      id: row.id,
      name: row.name,
      unit: row.unit,
    })),
  };

  const response = await fetch(`${baseUrl}/chat/completions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: 0.1,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        {
          role: "user",
          content: JSON.stringify({
            transcript,
            candidates: candidatePayload,
          }),
        },
      ],
    }),
    signal: AbortSignal.timeout(25_000),
  });

  if (!response.ok) {
    const detail = await response.text();
    console.error("OpenAI error", response.status, detail.slice(0, 500));
    throw new HttpError(502, "خدمة الذكاء الاصطناعي لم تستجب، حاول لاحقاً");
  }

  const completion = await response.json();
  const content = completion?.choices?.[0]?.message?.content;
  if (typeof content !== "string" || !content.trim()) {
    throw new HttpError(502, "لم تُرجع خدمة الذكاء الاصطناعي نتيجة");
  }

  try {
    return JSON.parse(stripCodeFence(content)) as LlmPlan;
  } catch {
    throw new HttpError(502, "تعذر تحليل استجابة الذكاء الاصطناعي");
  }
}

class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (request.method !== "POST") {
    return json({ error: "طريقة الطلب غير مدعومة" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceKey) {
      return json({ error: "إعداد الخادم غير مكتمل" }, 500);
    }

    const authHeader = request.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) {
      return json({ error: "الجلسة غير صالحة، سجّل الدخول من جديد" }, 401);
    }

    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: userData, error: userError } = await authClient.auth.getUser(
      token,
    );
    if (userError || !userData.user) {
      return json({ error: "الجلسة غير صالحة، سجّل الدخول من جديد" }, 401);
    }
    const userId = userData.user.id;

    let body: { transcript?: string; type_hint?: string };
    try {
      body = await request.json();
    } catch {
      return json({ error: "صيغة الطلب غير صحيحة" }, 400);
    }

    const transcript = (body.transcript ?? "").trim();
    if (!transcript) {
      return json({ error: "لم يتم استلام أي نص" }, 400);
    }
    if (transcript.length > MAX_TRANSCRIPT_LENGTH) {
      return json({ error: "النص المسموع طويل جداً" }, 413);
    }

    const db = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const [customersResult, suppliersResult, productsResult] = await Promise
      .all([
        db.from("customers")
          .select("id,name,phone")
          .eq("user_id", userId)
          .order("name")
          .limit(CANDIDATE_LIMIT),
        db.from("suppliers")
          .select("id,name,phone")
          .eq("user_id", userId)
          .order("name")
          .limit(CANDIDATE_LIMIT),
        db.from("products")
          .select("id,name,unit,measurement,sale_price,purchase_price")
          .eq("user_id", userId)
          .eq("is_active", true)
          .order("name")
          .limit(CANDIDATE_LIMIT),
      ]);

    if (customersResult.error || suppliersResult.error || productsResult.error) {
      console.error(
        "candidate query error",
        customersResult.error,
        suppliersResult.error,
        productsResult.error,
      );
      return json({ error: "تعذر قراءة البيانات من الخادم" }, 500);
    }

    const customers = (customersResult.data ?? []) as PartyRow[];
    const suppliers = (suppliersResult.data ?? []) as PartyRow[];
    const products = (productsResult.data ?? []) as ProductRow[];

    const plan = await askModel(transcript, {
      customers,
      suppliers,
      products,
    });

    const hint = body.type_hint === "purchase" ? "purchase" : null;
    const invoiceType: InvoiceType =
      plan.invoice_type === "purchase" || plan.invoice_type === "sale"
        ? plan.invoice_type
        : hint ?? "sale";
    const paymentType: PaymentType =
      plan.payment_type === "cash" ? "cash" : "debt";

    const warnings: string[] = [];
    const partyRows = invoiceType === "sale" ? customers : suppliers;
    const productById = new Map(products.map((row) => [row.id, row]));

    let partyId = plan.party?.party_id ?? null;
    let party = partyId ? partyRows.find((row) => row.id === partyId) : null;
    if (!party) {
      party = bestMatch(plan.party?.spoken_name, partyRows);
      partyId = party?.id ?? null;
    }
    if (!party) {
      warnings.push(
        invoiceType === "sale"
          ? "لم يتم العثور على العميل المذكور"
          : "لم يتم العثور على المورد المذكور",
      );
    }

    const merged = new Map<
      string,
      {
        product: ProductRow;
        quantity: number;
        spokenName: string;
      }
    >();
    const unmatched: Array<{ spoken_name: string; quantity: number }> = [];

    for (const rawItem of plan.items ?? []) {
      const quantity = toQuantity(rawItem.quantity);
      const spokenName = (rawItem.spoken_name ?? "").trim();
      let product = rawItem.product_id
        ? productById.get(rawItem.product_id) ?? null
        : null;
      if (!product) {
        product = bestMatch(spokenName, products);
      }
      if (!product) {
        if (spokenName) {
          unmatched.push({ spoken_name: spokenName, quantity });
        }
        continue;
      }

      const existing = merged.get(product.id);
      if (existing) {
        existing.quantity += quantity;
      } else {
        merged.set(product.id, { product, quantity, spokenName });
      }
    }

    if (unmatched.length > 0) {
      warnings.push(
        `${unmatched.length} منتج لم يتم العثور عليه في المخزون`,
      );
    }

    const items = [...merged.values()].map(({ product, quantity, spokenName }) => {
      const unitPrice = invoiceType === "sale"
        ? toNumber(product.sale_price)
        : toNumber(product.purchase_price);
      return {
        product_id: product.id,
        name: product.name,
        spoken_name: spokenName || product.name,
        quantity,
        unit: product.unit ?? "",
        measurement: product.measurement ?? "",
        unit_price: unitPrice,
        sale_price: toNumber(product.sale_price),
        purchase_price: toNumber(product.purchase_price),
        total_price: unitPrice * quantity,
        matched: true,
      };
    });

    if (items.length === 0) {
      warnings.push("لم يتم التعرف على أي منتج من النص");
    }

    return json({
      transcript,
      invoice_type: invoiceType,
      payment_type: paymentType,
      confidence: Math.min(1, Math.max(0, toNumber(plan.confidence))),
      party: {
        party_type: invoiceType === "sale" ? "customer" : "supplier",
        id: partyId,
        name: party?.name ?? (plan.party?.spoken_name ?? "").trim(),
        phone: party?.phone ?? null,
        matched: party != null,
      },
      items,
      unmatched_items: unmatched,
      warnings,
    });
  } catch (error) {
    if (error instanceof HttpError) {
      return json({ error: error.message }, error.status);
    }
    console.error("voice-invoice failure", error);
    return json({ error: "خطأ في الخادم" }, 500);
  }
});
```
