import { z } from "zod";

/** Ein Loch bzw. eine Bahn. Bei Minigolf sind par/hcp/length meist leer. */
export const holeSchema = z.object({
  number: z.number().int().min(1).max(36),
  par: z.number().int().min(1).max(8).nullable().default(null),
  hcp: z.number().int().min(1).max(36).nullable().default(null),
  length: z.number().int().min(1).max(1200).nullable().default(null),
  teeLat: z.number().min(-90).max(90).nullable().default(null),
  teeLon: z.number().min(-180).max(180).nullable().default(null),
  flagLat: z.number().min(-90).max(90).nullable().default(null),
  flagLon: z.number().min(-180).max(180).nullable().default(null),
});

export type Hole = z.infer<typeof holeSchema>;

export const courseKind = z.enum(["golf", "minigolf"]);
export const courseStatus = z.enum(["pending", "approved", "rejected"]);

export type CourseKind = z.infer<typeof courseKind>;
export type CourseStatus = z.infer<typeof courseStatus>;

const trimmed = (max: number) => z.string().trim().max(max);
const optionalUrl = z
  .string()
  .trim()
  .max(200)
  .refine((v) => v === "" || /^https?:\/\/\S+\.\S+/.test(v), "invalid_url")
  .default("");

/** Was das öffentliche Formular schickt. */
export const submissionSchema = z
  .object({
    kind: courseKind,
    name: trimmed(120).min(2),
    location: trimmed(160).default(""),
    country: trimmed(2).default("DE"),
    holes: z.number().int().min(1).max(36),
    latitude: z.number().min(-90).max(90).nullable().default(null),
    longitude: z.number().min(-180).max(180).nullable().default(null),
    courseRating: z.number().min(50).max(90).nullable().default(null),
    slopeRating: z.number().int().min(55).max(155).nullable().default(null),
    holeData: z.array(holeSchema).max(36).default([]),
    facilityNotes: trimmed(2000).default(""),
    welcome: trimmed(400).default(""),
    website: optionalUrl,
    phone: trimmed(60).default(""),
    publicEmail: z.union([z.literal(""), z.string().trim().email()]).default(""),
    submitterName: trimmed(120).min(2),
    submitterEmail: z.string().trim().email(),
    submitterRole: trimmed(120).default(""),
    consent: z.literal(true),
    /** Honigtopf – Bots füllen ihn aus, Menschen sehen ihn nicht. */
    company: z.string().max(0).default(""),
  })
  .superRefine((value, ctx) => {
    if (value.holeData.length && value.holeData.length !== value.holes) {
      ctx.addIssue({ code: "custom", path: ["holeData"], message: "hole_count_mismatch" });
    }
    const hcps = value.holeData.map((h) => h.hcp).filter((h): h is number => h !== null);
    if (new Set(hcps).size !== hcps.length) {
      ctx.addIssue({ code: "custom", path: ["holeData"], message: "hcp_not_unique" });
    }
    if (value.kind === "golf" && value.holeData.some((h) => h.par === null)) {
      ctx.addIssue({ code: "custom", path: ["holeData"], message: "par_required" });
    }
  });

export type SubmissionInput = z.infer<typeof submissionSchema>;

/** Änderungen aus dem Adminpanel. */
export const adminUpdateSchema = z.object({
  name: trimmed(120).min(2).optional(),
  location: trimmed(160).optional(),
  country: trimmed(2).optional(),
  holes: z.number().int().min(1).max(36).optional(),
  latitude: z.number().min(-90).max(90).nullable().optional(),
  longitude: z.number().min(-180).max(180).nullable().optional(),
  courseRating: z.number().min(50).max(90).nullable().optional(),
  slopeRating: z.number().int().min(55).max(155).nullable().optional(),
  holeData: z.array(holeSchema).max(36).optional(),
  facilityNotes: trimmed(2000).optional(),
  welcome: trimmed(400).optional(),
  website: optionalUrl.optional(),
  phone: trimmed(60).optional(),
  publicEmail: z.union([z.literal(""), z.string().trim().email()]).optional(),
  adminNotes: trimmed(2000).optional(),
  slug: z
    .string()
    .trim()
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "invalid_slug")
    .max(80)
    .optional(),
});

export type AdminUpdate = z.infer<typeof adminUpdateSchema>;

// MARK: – Werbung

/** `draft` = nur im Adminpanel, `active` = wird ausgeliefert, `paused` = ruht. */
export const adStatus = z.enum(["draft", "active", "paused"]);
/** Bislang nur ein Platz: die freie Fläche unter den Namen in der Minigolfkarte. */
export const adPlacement = z.enum(["minigolf_scoring"]);

export type AdStatus = z.infer<typeof adStatus>;
export type AdPlacement = z.infer<typeof adPlacement>;

const slugOrEmpty = z
  .string()
  .trim()
  .max(80)
  .refine((v) => v === "" || /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(v), "invalid_slug")
  .default("");

/**
 * Tagesdatum aus `<input type="date">`. `null` heißt „unbegrenzt"; die leere
 * Eingabe wandelt der Aufrufer vorher um – so wie bei den Zahlenfeldern auch.
 */
const dateOrNull = z
  .string()
  .trim()
  .regex(/^\d{4}-\d{2}-\d{2}$/, "invalid_date")
  .nullable()
  .default(null);

/**
 * Eine Anzeige. Die Längen sind an den Platz im Banner angelehnt: mehr passt
 * auf 64 Punkt Höhe nicht, ohne dass die Schrift unlesbar klein wird.
 */
export const adSchema = z
  .object({
    status: adStatus.default("draft"),
    placement: adPlacement.default("minigolf_scoring"),
    /** Leer = überall. Sonst nur auf dieser Anlage. */
    courseSlug: slugOrEmpty,
    title: trimmed(40).min(2),
    subtitle: trimmed(80).default(""),
    imageURL: optionalUrl,
    linkURL: optionalUrl,
    advertiser: trimmed(120).default(""),
    weight: z.number().int().min(1).max(100).default(1),
    startsOn: dateOrNull,
    endsOn: dateOrNull,
    adminNotes: trimmed(2000).default(""),
  })
  .superRefine((value, ctx) => {
    if (value.startsOn && value.endsOn && value.startsOn > value.endsOn) {
      ctx.addIssue({ code: "custom", path: ["endsOn"], message: "end_before_start" });
    }
  });

export type AdInput = z.infer<typeof adSchema>;

/**
 * Was ein Anlagenbetreiber auf `/werbung` einreicht. Daraus wird ein Entwurf
 * im Adminpanel – geschaltet wird erst nach Rückfrage und von Hand.
 */
export const adRequestSchema = z.object({
  courseSlug: z
    .string()
    .trim()
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "invalid_slug")
    .max(80),
  title: trimmed(40).min(2),
  subtitle: trimmed(80).default(""),
  linkURL: optionalUrl,
  imageURL: optionalUrl,
  advertiser: trimmed(120).default(""),
  submitterName: trimmed(120).min(2),
  submitterEmail: z.string().trim().email(),
  submitterPhone: trimmed(60).default(""),
  requestNote: trimmed(2000).default(""),
  consent: z.literal(true),
  /** Honigtopf – Bots füllen ihn aus, Menschen sehen ihn nicht. */
  company: z.string().max(0).default(""),
});

export type AdRequestInput = z.infer<typeof adRequestSchema>;

/** Zählmeldung aus der App. Ohne Schlüssel, deshalb nach oben gedeckelt. */
export const adEventBatchSchema = z.object({
  events: z
    .array(
      z.object({
        id: z.string().uuid(),
        type: z.enum(["impression", "click"]),
        count: z.number().int().min(1).max(100).default(1),
      }),
    )
    .min(1)
    .max(50),
});

export type AdEventBatch = z.infer<typeof adEventBatchSchema>;
