const BASE_AUTHORITY = "otl.kaist.ac.kr";

const SESSION_URL = "session/";
const SESSION_INFO_URL = SESSION_URL + "info";
const SESSION_REFRESH_URL = SESSION_URL + "refresh";

const API_URL = "api/";
const API_SEMESTER_URL = API_URL + "semesters";
const API_COURSE_URL = API_URL + "courses";
const API_COURSE_LECTURE_URL = API_COURSE_URL + "/{id}/lectures";
const API_COURSE_REVIEW_URL = API_COURSE_URL + "/{id}/reviews";
const API_LECTURE_URL = API_URL + "lectures";
const API_LECTURE_RELATED_REVIEWS_URL =
    API_LECTURE_URL + "/{id}/related-reviews";
const API_REVIEW_URL = API_URL + "reviews";
const API_REVIEW_LIKE_URL = API_REVIEW_URL + "/{id}/like";
const API_TIMETABLE_URL = API_URL + "users/{user_id}/timetables";
const API_TIMETABLE_ADD_LECTURE_URL =
    API_TIMETABLE_URL + "/{timetable_id}/add-lecture";
const API_TIMETABLE_REMOVE_LECTURE_URL =
    API_TIMETABLE_URL + "/{timetable_id}/remove-lecture";
const API_LIKED_REVIEW_URL = API_URL + "/users/{user_id}/liked-reviews";
const API_SHARE_URL = API_URL + "share/timetable/{share_type}";

enum ShareType { image, ical }

const CONTACT = "otlplus@sparcs.org";
