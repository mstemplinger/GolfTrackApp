"use server";

import { revalidatePath } from "next/cache";
import { isAuthenticated } from "@/lib/auth";
import { decideNameRequest } from "@/lib/courseNameRequests";

/** Namenswunsch eines Betreibers freigeben oder ablehnen. */
export async function decideName(formData: FormData): Promise<void> {
  if (!(await isAuthenticated())) throw new Error("not_authenticated");
  const id = String(formData.get("id") ?? "");
  const approve = formData.get("decision") === "approve";
  const req = await decideNameRequest(id, approve);
  revalidatePath("/admin");
  if (req) {
    revalidatePath(`/admin/${req.courseSlug}`);
    if (approve) {
      // Öffentliche Seiten des Platzes zeigen den neuen Namen sofort.
      revalidatePath(`/golf/${req.courseSlug}`);
      revalidatePath(`/minigolf/${req.courseSlug}`);
      revalidatePath("/plaetze");
    }
  }
}
