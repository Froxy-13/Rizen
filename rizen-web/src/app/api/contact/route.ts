import { NextRequest, NextResponse } from "next/server";
import nodemailer from "nodemailer";

export async function POST(req: NextRequest) {
  const { name, email, topic, message } = await req.json();

  if (!name || !email || !topic || !message) {
    return NextResponse.json({ error: "Champs manquants." }, { status: 400 });
  }

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.GMAIL_USER,
      pass: process.env.GMAIL_APP_PASSWORD,
    },
  });

  await transporter.sendMail({
    from: `"${name}" <${process.env.GMAIL_USER}>`,
    replyTo: email,
    to: process.env.GMAIL_USER,
    subject: `[Assistance Rizen] ${topic}`,
    text: `De : ${name} <${email}>\nSujet : ${topic}\n\n${message}`,
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;">
        <h2 style="color:#131b2d;">Nouveau message — Centre d'assistance Rizen</h2>
        <table style="width:100%;border-collapse:collapse;margin-bottom:16px;">
          <tr><td style="padding:8px;color:#666;width:120px;">Nom</td><td style="padding:8px;font-weight:600;">${name}</td></tr>
          <tr style="background:#f5f5f5;"><td style="padding:8px;color:#666;">Email</td><td style="padding:8px;">${email}</td></tr>
          <tr><td style="padding:8px;color:#666;">Sujet</td><td style="padding:8px;font-weight:600;">${topic}</td></tr>
        </table>
        <div style="background:#f9f9f9;border-left:4px solid #e07b39;padding:16px;border-radius:4px;">
          <p style="margin:0;white-space:pre-wrap;">${message}</p>
        </div>
        <p style="color:#999;font-size:12px;margin-top:24px;">Message envoyé via le Centre d'assistance Rizen Marketplace</p>
      </div>
    `,
  });

  return NextResponse.json({ ok: true });
}
