const BASE_AUTHORITY = "otl.kaist.ac.kr";

// Retained v1 endpoints: session, legacy lecture/review details, and sharing.
const SESSION_URL = "session/";
const SESSION_INFO_URL = SESSION_URL + "info";
const SESSION_REFRESH_URL = SESSION_URL + "refresh";

const API_URL = "api/";

const API_SEMESTER_URL = API_URL + "semesters";
const API_COURSE_LECTURE_URL = API_URL + "courses/{id}/lectures";
const API_COURSE_REVIEW_URL = API_URL + "courses/{id}/reviews";
const API_LECTURE_RELATED_REVIEWS_URL =
    API_URL + "lectures/{id}/related-reviews";
const API_COURSE_URL = API_URL + "courses";
const API_LECTURE_URL = API_URL + "lectures";
const API_REVIEW_URL = API_URL + "reviews";
const API_REVIEW_LIKE_URL = API_REVIEW_URL + "/{id}/like";
const API_TIMETABLE_URL = API_URL + "users/{user_id}/timetables";
const API_TIMETABLE_ADD_LECTURE_URL =
    API_TIMETABLE_URL + "/{timetable_id}/add-lecture";
const API_TIMETABLE_REMOVE_LECTURE_URL =
    API_TIMETABLE_URL + "/{timetable_id}/remove-lecture";
const API_LIKED_REVIEW_URL = API_URL + "users/{user_id}/liked-reviews";
const API_SHARE_URL = API_URL + "share/timetable/{share_type}";

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
const API_V2_TIMETABLE_DETAIL_URL = API_V2_TIMETABLES_URL + "/{id}";
const API_V2_USERS_INFO_URL = API_V2_URL + "users/info";
const API_V2_LIKED_REVIEWS_URL = API_V2_URL + "users/{user_id}/reviews/liked";
const API_V2_DEPARTMENT_OPTIONS_URL = API_V2_URL + "department-options";

enum ShareType { image, ical }

const CONTACT = "otlplus@sparcs.org";
