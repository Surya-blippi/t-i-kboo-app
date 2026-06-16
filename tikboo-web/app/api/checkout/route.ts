import { NextRequest, NextResponse } from "next/server";

export const runtime = "nodejs";

// Creates a DodoPayments one-time hosted checkout link for the unlock product.
export async function POST(req: NextRequest) {
  const apiKey = process.env.DODO_API_KEY;
  const base = process.env.DODO_BASE_URL || "https://test.dodopayments.com";
  const { pack, email } = await req.json().catch(() => ({ pack: "single" }));
  // pack: "single" → 1 credit, "pack" → 10 credits
  const productId =
    pack === "pack" ? process.env.DODO_PRODUCT_PACK : process.env.DODO_PRODUCT_SINGLE;
  const credits = pack === "pack" ? 10 : 1;
  if (!apiKey || !productId) {
    return NextResponse.json({ error: "Payments not configured." }, { status: 500 });
  }

  const origin = req.headers.get("origin") || new URL(req.url).origin;

  try {
    const res = await fetch(`${base}/payments`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        payment_link: true,
        product_cart: [{ product_id: productId, quantity: 1 }],
        customer: { email: email || "guest@tikboo.app", name: "tikboo user" },
        billing: { country: "IN", city: "NA", state: "NA", street: "NA", zipcode: "000000" },
        return_url: `${origin}/?dodo=return`,
        metadata: { kind: "credits", credits: String(credits) },
      }),
    });
    const data = await res.json();
    if (!res.ok || !data.payment_link) {
      return NextResponse.json(
        { error: data?.message || "Could not start checkout." },
        { status: 502 }
      );
    }
    return NextResponse.json({ url: data.payment_link, paymentId: data.payment_id, credits });
  } catch (e: any) {
    return NextResponse.json({ error: e?.message || "Checkout failed." }, { status: 502 });
  }
}
