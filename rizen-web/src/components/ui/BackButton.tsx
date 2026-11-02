"use client";

import { useRouter } from "next/navigation";

export default function BackButton() {
  const router = useRouter();
  return (
    <button
      onClick={() => router.back()}
      className="inline-flex items-center gap-1.5 text-label-md text-secondary hover:text-primary-container transition-colors"
    >
      <span className="material-symbols-outlined text-[16px]">arrow_back</span>
      Retour
    </button>
  );
}
