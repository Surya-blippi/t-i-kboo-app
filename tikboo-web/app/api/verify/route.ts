import { NextRequest, NextResponse } from "next/server";

export const runtime = "nodejs";

// Verifies a DodoPayments payment by id — used after the checkout redirect.
export async function GET(req: NextRequest) {
  const apiKey = process.env.DODO_API_KEY;
  const base = process.env.DODO_BASE_URL || "https://test.dodopayments.com";
  const id = new URL(req.url).searchParams.get("payment_id");
  if (!apiKey) return NextResponse.json({ error: "Not configured." }, { status: 500 });
  if (!id) return NextResponse.json({ paid: false }, { status: 400 });

  try {
    const res = await fetch(`${base}/payments/${id}`, {
      headers: { Authorization: `Bearer ${apiKey}` },
    });
    const data = await res.json();
    const status = String(data?.status || "").toLowerCase();
    return NextResponse.json({ paid: status === "succeeded", status });
  } catch (e: any) {
    return NextResponse.json({ paid: false, error: e?.message }, { status: 502 });
  }
}
