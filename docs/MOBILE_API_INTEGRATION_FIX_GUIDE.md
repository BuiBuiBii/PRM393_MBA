# Mobile API Integration Fix Guide

Tai lieu nay duoc viet tu source Backend hien tai, khong doan endpoint. Muc tieu la giup Mobile sua dung 2 loi tich hop:

1. User roadmap progress hien thi sai hoac khong cap nhat.
2. Admin man hinh xem ket qua phan tich repository render sai cau truc response.

Backend wrapper chung:

```json
{
  "success": true,
  "message": "...",
  "data": {},
  "errorCode": null
}
```

## 1. Roadmap Progress Cua User

### API chuan Mobile phai goi

Base route mount: `src/app.js` mount `src/routes/roadmap.routes.js` tai `/api/roadmaps`.

Tat ca API ben duoi dung `authMiddleware` (`Authorization: Bearer <jwt>`). Middleware doc `req.user` tu JWT va service lay user id tu `req.user.userId` / `_id` / `id`.

#### Lay danh sach roadmap cua user

- Method: `GET`
- Endpoint: `/api/roadmaps/me`
- Route: `src/routes/roadmap.routes.js`
- Controller: `roadmapController.getMyRoadmaps`
- Service: `roadmapService.getMyRoadmaps`
- Query params:
  - `status`: optional, `active` hoac `archived`
  - `targetRole`: optional string
- Body: none
- Response data:

```json
{
  "roadmaps": [
    {
      "roadmapId": "665f1f000000000000000001",
      "title": "Backend Developer MVP Path",
      "targetRole": "Backend Developer",
      "roleId": "backend",
      "requestedLevel": "beginner",
      "effectiveLevel": "beginner",
      "durationWeeks": 6,
      "language": "vi",
      "roadmapSource": {},
      "roleMatch": {},
      "skillGapSummary": [],
      "mainRoadmap": { "title": "...", "targetRole": "...", "reason": "...", "phases": [] },
      "alternativeRoadmaps": [],
      "progressSummary": {
        "totalItems": 10,
        "completedItems": 0,
        "inProgressItems": 0,
        "overallProgress": 0
      },
      "createdAt": "2026-07-01T00:00:00.000Z",
      "updatedAt": "2026-07-01T00:00:00.000Z"
    }
  ]
}
```

Luu y: API nay co `progressSummary`, nhung neu Mobile can trang thai moi nhat va danh sach task progress thi phai goi API progress rieng ben duoi.

#### Lay chi tiet roadmap cua user

- Method: `GET`
- Endpoint: `/api/roadmaps/{roadmapId}`
- Route: `src/routes/roadmap.routes.js`
- Controller: `roadmapController.getRoadmapDetail`
- Service: `roadmapService.getRoadmapById`
- Params:
  - `roadmapId`: Mongo ObjectId
- Query params: none
- Body: none
- Response data:

```json
{
  "roadmap": {
    "roadmapId": "665f1f000000000000000001",
    "mainRoadmap": {
      "phases": [
        {
          "title": "Phase 1",
          "goal": "...",
          "skills": ["REST API"],
          "tasks": [
            {
              "itemId": "main-1-1-rest-api",
              "title": "Build REST API",
              "description": "...",
              "skillName": "REST API",
              "canonicalSkillName": "REST API",
              "category": "backend",
              "targetRole": "Backend Developer",
              "level": "beginner",
              "priority": "high",
              "week": 1,
              "estimatedHours": 4,
              "status": "not_started"
            }
          ],
          "status": "not_started"
        }
      ]
    },
    "alternativeRoadmaps": [],
    "progressSummary": {
      "totalItems": 1,
      "completedItems": 0,
      "inProgressItems": 0,
      "overallProgress": 0
    }
  }
}
```

Ket luan tich hop: task key phai la `itemId`. Khong dung Mongo `_id`, khong dung `skillName` lam key UI/update.

#### Lay progress chuan cua roadmap

- Method: `GET`
- Endpoint: `/api/roadmaps/{roadmapId}/progress`
- Route: `src/routes/roadmap.routes.js`
- Controller: `roadmapProgressController.getRoadmapProgress`
- Service: `roadmapProgressService.getRoadmapProgress`
- Model: `RoadmapProgress`
- Params:
  - `roadmapId`: Mongo ObjectId
- Query params: none
- Body: none
- Response data:

```json
{
  "roadmapId": "665f1f000000000000000001",
  "progressSummary": {
    "totalItems": 1,
    "completedItems": 0,
    "inProgressItems": 0,
    "overallProgress": 0
  },
  "items": [
    {
      "itemId": "main-1-1-rest-api",
      "title": "Build REST API",
      "skillName": "REST API",
      "canonicalSkillName": "REST API",
      "category": "backend",
      "targetRole": "Backend Developer",
      "level": "beginner",
      "priority": "high",
      "status": "not_started",
      "progressPercent": 0,
      "startedAt": null,
      "completedAt": null,
      "updatedAt": "2026-07-01T00:00:00.000Z"
    }
  ]
}
```

Mobile User screen phai lay phan tram tu:

```text
data.progressSummary.overallProgress
```

Khong tu tinh tu `mainRoadmap.phases[].tasks[].status` trong roadmap detail.

#### Cap nhat trang thai mot task

- Method: `PATCH`
- Endpoint: `/api/roadmaps/{roadmapId}/progress/items`
- Route: `src/routes/roadmap.routes.js`
- Controller: `roadmapProgressController.updateRoadmapItemStatus`
- Service: `roadmapProgressService.updateRoadmapItemStatus`
- Params:
  - `roadmapId`: Mongo ObjectId
- Body:

```json
{
  "itemId": "main-1-1-rest-api",
  "status": "completed",
  "progressPercent": 100
}
```

- `itemId`: required theo contract Mobile. Service van ho tro `skillName` fallback, nhung neu nhieu item cung skill se loi `400`.
- `status`: bat buoc la `not_started`, `in_progress`, hoac `completed`.
- `progressPercent`: optional. Chi co y nghia voi `in_progress`; completed luon thanh 100.
- Response data tra lai toan bo progress moi:

```json
{
  "roadmapId": "665f1f000000000000000001",
  "progressSummary": {
    "totalItems": 1,
    "completedItems": 1,
    "inProgressItems": 0,
    "overallProgress": 100
  },
  "items": [
    {
      "itemId": "main-1-1-rest-api",
      "status": "completed",
      "progressPercent": 100,
      "startedAt": "2026-07-01T00:00:00.000Z",
      "completedAt": "2026-07-01T00:00:00.000Z"
    }
  ]
}
```

Sau PATCH, Mobile co the dung ngay `data.progressSummary.overallProgress` trong response, hoac goi lai `GET /api/roadmaps/{roadmapId}/progress`.

#### Reset progress

- Method: `POST`
- Endpoint: `/api/roadmaps/{roadmapId}/progress/reset`
- Controller: `roadmapProgressController.resetRoadmapProgress`
- Service: `roadmapProgressService.resetRoadmapProgress`
- Body: none
- Response: cung schema voi GET progress, tat ca item ve `not_started`, `progressPercent = 0`.

#### Learning availability va learning content

Dung cho flow hoc roadmap, nhung cac API nay khong tu mark task completed.

- `GET /api/roadmaps/{roadmapId}/learning`
  - Controller: `roadmapLearningController.getRoadmapLearning`
  - Service: `roadmapLearningService.getRoadmapLearning`
  - Response data: `{ roadmapId, sourceMode, language, items[] }`
  - Moi item co `itemId`, `taskTitle`, `canonicalSkillName`, `skillName`, `targetRole`, `level`, `week`, `priority`, `learningStatus`.
- `GET /api/roadmaps/{roadmapId}/learning/items/{itemId}?includeResources=true`
  - Response data: `{ roadmapId, itemId, task, learning, personalizedContext, progress }`
  - `progress` chi gom `{ status, progressPercent }` neu co `RoadmapProgress` record.
- `POST /api/roadmaps/{roadmapId}/learning/items/{itemId}/generate`
  - Body optional: `{ "forceRegenerate": false, "includeResources": true }`
  - Generate/fetch learning content. Khong cap nhat completed status.

### Nguon du lieu va cong thuc progress

Source of truth cua progress la collection/model `RoadmapProgress` (`src/models/RoadmapProgress.js`):

```js
{
  userId,
  roadmapId,
  items: [
    {
      itemId,
      status,
      progressPercent,
      startedAt,
      completedAt,
      updatedAt
    }
  ],
  overallProgress,
  progressSummary
}
```

Backend tinh summary trong `roadmapProgress.service.js`:

```text
validItems = items co itemId khong rong
totalItems = validItems.length
completedItems = count(status == "completed")
inProgressItems = count(status == "in_progress")
overallProgress = totalItems ? Math.round(completedItems / totalItems * 100) : 0
```

Quy tac item percent:

- `completed` -> `progressPercent = 100`
- `in_progress` -> neu client gui so hop le thi round va clamp trong khoang `1..99`; neu khong gui thi `50`
- `not_started` -> `progressPercent = 0`

Chi `status === "completed"` moi duoc tinh vao `completedItems` va `overallProgress`. `in_progress` khong cong mot phan vao percent tong. Backend khong thay logic loai tru optional task; moi item co `itemId` trong roadmap main/alternative deu duoc tinh.

Progress duoc luu trong database (`RoadmapProgress.progressSummary`, `RoadmapProgress.overallProgress`) va dong bo snapshot sang `Roadmap.progressSummary` sau moi lan get/create/update/reset progress. Khi roadmap task thay doi, `getOrCreateRoadmapProgress` se sync lai items tu roadmap tasks.

Khong co API recalculate/refresh rieng. Goi `GET /api/roadmaps/{roadmapId}/progress` se tao/sync progress record neu chua co.

### So sanh User va Admin

Admin route mount: `/api/admin`, dung `authMiddleware` + `adminMiddleware`.

Admin roadmap list:

- `GET /api/admin/roadmaps`
- Service: `adminService.getRoadmaps`
- Backend doc `RoadmapProgress` theo `roadmapId + ownerUserId`, roi format `progressSummary`.

Admin roadmap detail:

- `GET /api/admin/roadmaps/{roadmapId}`
- Service: `adminService.getRoadmapById`
- Backend lay `RoadmapProgress.findOne({ roadmapId, userId: ownerUserId })`
- `formatAdminRoadmapResponse(... includeLearningProgress: true)` merge task metadata voi progress items.
- `mergeRoadmapProgressItems` tinh lai:

```text
overallProgress = Math.round(completedTasks / totalTaskMetadata * 100)
learningProgress.items[].status lay tu RoadmapProgress.items[].status theo itemId
```

Vi vay Admin dung vi no merge theo `RoadmapProgress.items`. User Mobile sai neu:

- chi render tu `GET /api/roadmaps/{roadmapId}` va doc `mainRoadmap.phases[].tasks[].status`;
- tu tinh percent tu task status trong roadmap detail;
- doc nham field cu nhu `progress`, `learningProgress`, `completionPercentage`, `completedTasks`;
- cap nhat task bang `skillName` thay vi `itemId`;
- sau khi PATCH khong dung response moi hoac khong refetch `/progress`.

Ket luan bat buoc cho Mobile User:

```text
Hien thi percent: data.progressSummary.overallProgress tu GET/PATCH /api/roadmaps/{roadmapId}/progress*
Hien thi task status: data.items[].status tu /progress
Map task UI: itemId
```

### Flow Mobile dung

1. Mo man roadmap:
   - Goi `GET /api/roadmaps/{roadmapId}` de lay noi dung roadmap.
   - Goi `GET /api/roadmaps/{roadmapId}/progress` de lay status/percent chuan.
2. Merge UI:
   - Render task tu `data.roadmap.mainRoadmap.phases[].tasks[]`.
   - Match status bang `itemId` voi `progress.items[]`.
   - Header percent lay tu `progress.progressSummary.overallProgress`.
3. Mo bai hoc:
   - Goi `GET /api/roadmaps/{roadmapId}/learning`.
   - Neu `learningStatus = available`, goi `GET /api/roadmaps/{roadmapId}/learning/items/{itemId}`.
   - Neu `missing`, goi `POST /api/roadmaps/{roadmapId}/learning/items/{itemId}/generate`.
4. User bam complete:
   - Goi `PATCH /api/roadmaps/{roadmapId}/progress/items` voi `{ itemId, status: "completed" }`.
5. Cap nhat UI:
   - Dung ngay `response.data.progressSummary.overallProgress`.
   - Hoac refetch `GET /api/roadmaps/{roadmapId}/progress`.
6. Khong tu tinh lai percent tu `mainRoadmap.phases[].tasks[].status`.

## 2. Admin Repository Analysis Result

### API analysis phia User va Admin

User analysis routes mount tai `/api/analysis`:

#### Chay analysis repository

- Method: `POST`
- Endpoint: `/api/analysis/repositories/{repoId}`
- Route: `src/routes/analysis.routes.js`
- Controller: `analysisController.analyzeRepository`
- Service: `analysisService.analyzeRepository`
- Auth: `authMiddleware`
- Params:
  - `repoId`: Repository Mongo `_id` hoac GitHub repo id
- Query params:
  - `view`: `summary` default, hoac `detail`
  - `includeEvidence`: boolean, chi co tac dung voi `view=detail`
  - `forceRegenerate`: boolean
- Body: optional, service nhan `body` nhung route contract khong yeu cau field bat buoc.
- Response data la analysis object truc tiep, khong boc trong `{ analysis }`.

#### Lay latest analysis cua mot repo

- Method: `GET`
- Endpoint: `/api/analysis/results/{repoId}`
- Controller: `analysisController.getAnalysisResults`
- Service: `analysisService.getAnalysisResults`
- Query:
  - `view=summary|detail`
  - `includeEvidence=true|false`
- Response data boc trong `{ analysis }`.

```json
{
  "analysis": {
    "analysisId": "665f1f000000000000000010",
    "snapshotId": null,
    "repository": {
      "repositoryId": "665f1f000000000000000002",
      "githubRepoId": 123456,
      "repoName": "WDP_G3",
      "fullName": "owner/WDP_G3"
    },
    "analysisScope": {
      "type": "user_contribution",
      "githubUsername": "student",
      "totalRepoCommits": 40,
      "userCommits": 12,
      "activeDays": 5,
      "firstCommitDate": "2026-07-01T00:00:00.000Z",
      "lastCommitDate": "2026-07-10T00:00:00.000Z"
    },
    "summary": {
      "careerDirection": "Backend Developer",
      "userLevel": "beginner",
      "userReadinessScore": 61,
      "overallScore": 61,
      "projectType": "Backend",
      "confidence": "medium"
    },
    "topSkills": [
      {
        "skill": "REST API",
        "canonicalSkillName": "REST API",
        "category": "backend",
        "score": 82.5,
        "level": "strong"
      }
    ],
    "missingSkills": [
      {
        "skill": "API Testing",
        "canonicalSkillName": "API Testing",
        "category": "Testing",
        "priority": "high"
      }
    ],
    "strengths": ["..."],
    "weaknesses": ["..."],
    "recommendations": ["..."],
    "createdAt": "2026-07-10T00:00:00.000Z"
  }
}
```

Voi `view=detail`, them:

```json
{
  "analysis": {
    "analyzedAt": "2026-07-10T00:00:00.000Z",
    "analysisScope": {
      "type": "user_contribution",
      "analyzedCommitShas": ["abc123"]
    },
    "scoreBreakdown": {
      "skillScore": 0,
      "contributionScore": 0,
      "commitQualityScore": 0,
      "projectCompletenessScore": 0,
      "missingCriticalPenalty": 0,
      "confidence": "medium"
    }
  }
}
```

Voi `view=detail&includeEvidence=true`, them:

```json
{
  "analysis": {
    "debug": {
      "skillVector": [
        {
          "skill": "REST API",
          "canonicalSkillName": "REST API",
          "normalizedSkillName": "rest api",
          "category": "backend",
          "score": 82.5,
          "level": "strong",
          "rawSimilarity": 0.825,
          "dev2vecStatus": "matched",
          "evidenceDetected": true,
          "evidenceStatus": "detected",
          "reason": "...",
          "evidence": ["..."],
          "sources": ["package", "api"],
          "lastCalculatedAt": "2026-07-10T00:00:00.000Z"
        }
      ],
      "dev2vec": {
        "modelVersion": "dev2vec-demo-v1",
        "vectorDims": {},
        "vectorSources": {},
        "sourceStats": {},
        "evidencePreview": {},
        "rolePredictions": [],
        "skillGaps": {},
        "scoringMethod": "dev2vec_doc2vec_classifier"
      }
    }
  }
}
```

#### Lay latest analysis cua tat ca repo cua user

- Method: `GET`
- Endpoint: `/api/analysis/me`
- Controller: `analysisController.getMyAnalysisResults`
- Service: `analysisService.getMyAnalysisResults`
- Query:
  - `view=summary|detail`
  - `includeEvidence`: accepted, nhung list item luon compact
- Response data:

```json
{
  "total": 1,
  "analyses": [
    {
      "analysisId": "665f1f000000000000000010",
      "snapshotId": null,
      "repository": {},
      "analysisScope": {},
      "summary": {},
      "topSkills": [],
      "missingSkills": [],
      "analyzedAt": "2026-07-10T00:00:00.000Z"
    }
  ]
}
```

Quan trong: list item tu `/api/analysis/me` xoa `strengths`, `weaknesses`, `recommendations`, `createdAt`, va khong tra `debug.skillVector` du co `view=detail`.

Admin analysis routes:

- `GET /api/admin/analysis`
  - Route: `src/routes/admin.routes.js`
  - Controller: `adminController.getAnalysis`
  - Service: `adminService.getAnalysis`
  - Auth: `authMiddleware` + `adminMiddleware`
  - Response data: `{ items, pagination }`
  - Items la raw `AnalysisSnapshot` documents co populate `userId`, `repositoryId`.
- `GET /api/admin/analysis/{analysisId}`
  - Controller: `adminController.getAnalysisById`
  - Service: `adminService.getAnalysisById`
  - Response data: `{ analysis }`
  - `analysis` la raw stored `AnalysisSnapshot`, khong qua `sanitizeAnalysisSnapshot`.

### Cau truc dung de Admin Mobile render analysis

Neu man Admin Mobile dang dung endpoint `/api/admin/analysis/{analysisId}`, khong render theo schema compact cua `/api/analysis/results/{repoId}`. Admin response la raw document, cac field nam truc tiep trong `data.analysis`:

```json
{
  "analysis": {
    "_id": "665f1f000000000000000010",
    "userId": {
      "_id": "665f1f000000000000000100",
      "fullName": "Student Name",
      "email": "student@example.com",
      "role": "student",
      "status": "active"
    },
    "repositoryId": {
      "_id": "665f1f000000000000000002",
      "name": "WDP_G3",
      "fullName": "owner/WDP_G3",
      "htmlUrl": "https://github.com/owner/WDP_G3",
      "language": "JavaScript"
    },
    "githubRepoId": 123456,
    "repoName": "WDP_G3",
    "fullName": "owner/WDP_G3",
    "analyzedAt": "2026-07-10T00:00:00.000Z",
    "projectType": "Backend",
    "languages": ["JavaScript"],
    "frameworks": ["Express"],
    "packages": ["express", "mongoose"],
    "configs": ["Docker"],
    "skillSignals": ["REST API", "Database"],
    "careerSignals": ["Backend Developer"],
    "careerDirection": "Backend Developer",
    "strengths": ["..."],
    "weaknesses": ["..."],
    "missingSkills": ["API Testing"],
    "recommendations": ["..."],
    "scores": {},
    "commitSummary": {},
    "checklist": {},
    "rawAnalysis": {}
  }
}
```

Khac biet chinh:

- Admin raw detail dung `_id`, khong phai `analysisId`.
- Repository metadata co the nam o `analysis.repositoryId` da populate, dong thoi van co `repoName`, `fullName`, `githubRepoId` top-level.
- `missingSkills` trong Admin raw la array string, khong phai array object `{ skill, canonicalSkillName, category, priority }`.
- `topSkills` khong phai field raw trong admin detail. Neu can top skills theo schema compact, Mobile phai dung user analysis endpoint `/api/analysis/results/{repoId}?view=detail`.
- `summary` trong raw `AnalysisResult` co the ton tai, nhung `AnalysisSnapshot` model admin dang import chi dinh nghia `scores`, `commitSummary`, `checklist`, `rawAnalysis` va cac mang top-level. UI admin nen fallback top-level `careerDirection`, `projectType`, `scores`.
- `debug.skillVector` chi co o `/api/analysis/results/{repoId}?view=detail&includeEvidence=true`, khong co o `/api/admin/analysis/{analysisId}`.

### Fix de xuat cho Admin Mobile

Neu man Admin can audit raw analysis snapshot:

```text
GET /api/admin/analysis/{analysisId}
Render tu data.analysis
Dung data.analysis._id
Dung data.analysis.repoName/fullName hoac data.analysis.repositoryId.name/fullName
Dung data.analysis.strengths/weaknesses/recommendations la array string
Dung data.analysis.missingSkills la array string
Khong expect topSkills/debug/summary compact
```

Neu man Admin muon hien thi dung compact analysis card nhu User:

```text
Lay repo id tu data.analysis.repositoryId._id hoac data.analysis.repositoryId
Goi GET /api/analysis/results/{repoId}?view=detail&includeEvidence=true bang account owner tuong ung se bi gioi han theo auth user.
Voi admin cross-user, Backend hien tai khong co admin endpoint compact serializer cho analysis detail.
```

Do do cach an toan nhat cho Mobile Admin hien tai la map theo raw admin response, khong dung model parser cua User analysis compact response.

## Checklist sua Mobile

- User roadmap percent: doc `GET /api/roadmaps/{roadmapId}/progress -> data.progressSummary.overallProgress`.
- User task status: doc `data.items[]` tu progress API va merge voi roadmap task bang `itemId`.
- Complete task: `PATCH /api/roadmaps/{roadmapId}/progress/items` voi `itemId`, khong dung `skillName` neu co `itemId`.
- Sau complete: dung response PATCH hoac refetch progress API.
- Learning API khong tu dong complete task; van phai PATCH progress.
- Admin analysis detail: neu dung `/api/admin/analysis/{analysisId}`, parse raw `data.analysis`, khong parse nhu `data.analysis.topSkills[]`/`debug.skillVector`.
- User analysis detail: neu dung `/api/analysis/results/{repoId}`, parse compact wrapper `data.analysis`.
