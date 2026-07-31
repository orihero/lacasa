import axios from "axios";
import { apiClient } from "./apiClient";

// Same signature/return shape as the old Firebase Storage version (resolves
// to a plain public URL string) so every caller (AdsAdd, AdsEdit,
// CoworkerAdd/Update, ProfileSetting, profileUpdatePage) needs no changes.
//
// Only the presign step goes through @lacasa/api-client — the PUT that
// follows is a raw binary upload of a browser File straight to the
// presigned MinIO URL (not our API's baseUrl, not bearer-authenticated),
// which is genuinely apps/web-specific and stays here rather than in the
// shared client (see packages/api-client/src/resources/uploads.ts).
export const assetUpload = async (file, scope = "ads") => {
  const data = await apiClient.uploads.presign({
    fileName: file.name,
    contentType: file.type,
    scope,
  });

  await axios.put(data.uploadUrl, file, {
    headers: { "Content-Type": file.type },
  });

  return data.publicUrl;
};
