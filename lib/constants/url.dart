const BASE_AUTHORITY = "otl.kaist.ac.kr";

// Retained v1 endpoints: session only.
const SESSION_URL = "session/";
const SESSION_LOGIN_URL = "session/login/";
const SESSION_INFO_URL = SESSION_URL + "info";
const SESSION_REFRESH_URL = SESSION_URL + "refresh";

// v2 endpoints. Responses contain one language selected by Accept-Language.
const API_V2_URL = "api/v2/";
const API_V2_COURSES_URL = API_V2_URL + "courses";
const API_V2_COURSE_DETAIL_URL = API_V2_COURSES_URL + "/{id}";
const API_V2_LECTURES_URL = API_V2_URL + "lectures";
const API_V2_REVIEWS_URL = API_V2_URL + "reviews";
const API_V2_REVIEW_DETAIL_URL = API_V2_REVIEWS_URL + "/{id}";
const API_V2_REVIEW_LIKED_URL = API_V2_REVIEW_DETAIL_URL + "/liked";
const API_V2_SEMESTERS_URL = API_V2_URL + "semesters";
const API_V2_CURRENT_SEMESTER_URL = API_V2_SEMESTERS_URL + "/current";
const API_V2_TIMETABLES_URL = API_V2_URL + "timetables";
const API_V2_MY_TIMETABLE_URL = API_V2_TIMETABLES_URL + "/my-timetable";
const API_V2_TIMETABLE_DETAIL_URL = API_V2_TIMETABLES_URL + "/{id}";
const API_V2_USER_INFO_URL = API_V2_URL + "users/info";
const API_V2_LIKED_REVIEWS_URL = API_V2_URL + "users/{user_id}/reviews/liked";
const API_V2_DEPARTMENT_OPTIONS_URL = API_V2_URL + "department-options";

enum ShareType { image, ical }

const CONTACT = "otlplus@sparcs.org";

abstract final class ExternalUrls {
  static const sparcsRecruiting = "https://apply.sparcs.org/";
  static const appEvent =
      "https://docs.google.com/forms/d/e/1FAIpQLSfZbU_TFUPN53De_ihtS4ZK5Tb_nRDazRS7EYQgp3QWAYvyhQ/viewform";
}
