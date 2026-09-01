import type { AdRecord } from "./ads";
import type { CourseRecord } from "./courses";

/**
 * Öffentliches JSON für die App. Die Feldnamen entsprechen bewusst
 * `BundledCourseEntry` bzw. `MinigolfCourseEntry` in der iOS-App, damit der
 * Import dort ohne Umrechnung auskommt.
 */
export interface FeedCourse {
  id: string;
  kind: "golf" | "minigolf";
  name: string;
  location: string;
  country: string;
  holes: number;
  lat: number | null;
  lon: number | null;
  parValues: number[];
  hcpValues: number[];
  holeLengths: number[];
  courseRating: number | null;
  slopeRating: number | null;
  facilityNotes: string;
  welcome: string;
  website: string;
  phone: string;
  email: string;
  teeLatitudes: number[];
  teeLongitudes: number[];
  flagLatitudes: number[];
  flagLongitudes: number[];
  updatedAt: string;
}

export interface Feed {
  version: number;
  generatedAt: string;
  count: number;
  courses: FeedCourse[];
}

/** Liefert das Array nur, wenn für *jedes* Loch ein Wert vorliegt. */
function column<T>(record: CourseRecord, pick: (hole: CourseRecord["holeData"][number]) => T | null): T[] {
  const holes = [...record.holeData].sort((a, b) => a.number - b.number);
  if (holes.length !== record.holes) return [];
  const values = holes.map(pick);
  return values.every((value) => value !== null && value !== undefined) ? (values as T[]) : [];
}

export function toFeedCourse(record: CourseRecord): FeedCourse {
  return {
    id: record.slug,
    kind: record.kind,
    name: record.name,
    location: record.location,
    country: record.country,
    holes: record.holes,
    lat: record.latitude,
    lon: record.longitude,
    parValues: column(record, (h) => h.par),
    hcpValues: column(record, (h) => h.hcp),
    holeLengths: column(record, (h) => h.length),
    courseRating: record.courseRating,
    slopeRating: record.slopeRating,
    facilityNotes: record.facilityNotes,
    welcome: record.welcome,
    website: record.website,
    phone: record.phone,
    email: record.publicEmail,
    teeLatitudes: column(record, (h) => h.teeLat),
    teeLongitudes: column(record, (h) => h.teeLon),
    flagLatitudes: column(record, (h) => h.flagLat),
    flagLongitudes: column(record, (h) => h.flagLon),
    updatedAt: record.updatedAt,
  };
}

export function toFeed(records: CourseRecord[]): Feed {
  const courses = records.map(toFeedCourse);
  return {
    version: 1,
    generatedAt: new Date().toISOString(),
    count: courses.length,
    courses,
  };
}

// MARK: – Werbung

/**
 * Die Anzeige, wie sie im Gerät ankommt. `courseID` ist die Kennung der
 * Anlage – leer heißt „überall". Die Feldnamen entsprechen `RemoteAd` in der
 * iOS-App.
 */
export interface FeedAd {
  id: string;
  placement: string;
  courseID: string;
  title: string;
  subtitle: string;
  imageURL: string;
  linkURL: string;
  advertiser: string;
  weight: number;
  startsOn: string | null;
  endsOn: string | null;
}

export interface AdFeed {
  version: number;
  generatedAt: string;
  count: number;
  ads: FeedAd[];
}

export function toFeedAd(record: AdRecord): FeedAd {
  return {
    id: record.id,
    placement: record.placement,
    courseID: record.courseSlug,
    title: record.title,
    subtitle: record.subtitle,
    imageURL: record.imageURL,
    linkURL: record.linkURL,
    advertiser: record.advertiser,
    weight: record.weight,
    startsOn: record.startsOn,
    endsOn: record.endsOn,
  };
}

export function toAdFeed(records: AdRecord[]): AdFeed {
  const ads = records.map(toFeedAd);
  return {
    version: 1,
    generatedAt: new Date().toISOString(),
    count: ads.length,
    ads,
  };
}
