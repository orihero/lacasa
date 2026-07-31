import axios from "axios";
import { api } from "./api";

// Same signature/return shape as the old Firebase Storage version (resolves
// to a plain public URL string) so every caller (AdsAdd, AdsEdit,
// CoworkerAdd/Update, ProfileSetting, profileUpdatePage) needs no changes.
export const assetUpload = async (file, scope = "ads") => {
  const { data } = await api.post("/uploads/presign", {
    fileName: file.name,
    contentType: file.type,
    scope,
  });

  await axios.put(data.uploadUrl, file, {
    headers: { "Content-Type": file.type },
  });

  return data.publicUrl;
};
