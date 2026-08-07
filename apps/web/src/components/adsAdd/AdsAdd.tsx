import React, { useEffect, useMemo, useState } from "react";
import "./adsAdd.scss";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import regionData from "@lacasa/domain/data/regions";
import { useUtilsStore } from "../../lib/utilsStore";
import ShareIcon from "@mui/icons-material/Share";
import { buildCaption, convertDisplayPrice } from "@lacasa/domain";
import type { CurrencyCodeKey } from "@lacasa/domain";
import type { InstagramAccount } from "@lacasa/api-client";
import {
  Dropzone,
  FileMosaic,
  FullScreen,
  ImagePreview,
  VideoPreview,
} from "@files-ui/react";
import type { ExtFile } from "@files-ui/react";
import { toast } from "react-toastify";
import { assetUpload } from "../../lib/assetUpload";
import axios from "axios";
import { api } from "../../lib/api";
import { fieldErrorMessage } from "../../lib/formErrors";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Avatar,
  Box,
  Button,
  Checkbox,
  FormControlLabel,
  Modal,
  Typography,
} from "@mui/material";
import ExpandIcon from "@mui/icons-material/ExpandMore";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import { useUserStore } from "../../lib/userStore";
import Carousel from "react-material-ui-carousel";
import VisibilityIcon from "@mui/icons-material/Visibility";
import ImageGrid from "./components/ImageGrid";
import IgProfileCard from "../igProfileCard/IgProfileCard";
import TgProfileCard from "../tgProfileCard/TgProfileCard";
import YtVideoCard from "../ytVideoCard/YtVideoCard";
import {
  pingExtension,
  requestCrosspost,
  publishInstagramServerSide,
  grantIgAssistConsent,
} from "../../services/crosspost";
import { useNavigate, useParams } from "react-router-dom";
import { Triangle } from "react-loader-spinner";
import { YTService } from "../../services/yt";
import type { ITGAccount } from "../../services/tg";

// Deliberately loose: publishSelectSocial mixes checked Instagram and
// Telegram accounts (see handleCheckboxChange, used by both networks'
// checkboxes), so this only pins down the two fields socialKey actually
// reads from either shape.
interface SelectableSocialAccount {
  id?: string | number;
  igUserId?: string;
}

interface AdOptionItem {
  id: number;
  key: string;
  value: string;
}

const AdsAdd = () => {
  const {
    register,
    formState: { errors },
    watch,
    getValues,
  } = useForm();
  const { t } = useTranslation();
  const { currentUser, fetchUserInfo } = useUserStore();
  // On this route :id is the agent/profile id — the ad itself doesn't exist
  // until submit. Cross-posts started here are therefore recorded against a
  // per-draft id and re-keyed onto the real ad id once it's created; using
  // :id would collide every listing by this agent onto one publication row.
  const { id } = useParams();
  const draftAdId = useMemo(() => `draft-${crypto.randomUUID()}`, []);
  const [hasDraftPublications, setHasDraftPublications] = useState(false);
  const [regionId, setRegionId] = useState(0);
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(false);
  const [extFiles, setExtFiles] = useState<ExtFile[]>([]);
  const [extFilesVideo, setExtFilesVideo] = useState<ExtFile[]>([]);
  const [publishSelectSocial, setPublishSelectSocial] = useState<
    SelectableSocialAccount[]
  >([]);
  const [imageSrc, setImageSrc] = useState<File | string | undefined>(
    undefined,
  );
  const [videoSrc, setVideoSrc] = useState<File | string | undefined>(
    undefined,
  );
  const [openModal, setOpenModal] = useState("");
  const [resTG, setResTg] = useState([]);
  const [priceType, setPriceType] = useState<CurrencyCodeKey>("uzs");
  const [isShort, setIsShort] = useState(false);
  const [photoOrVideo, setPhotoOrVideo] = useState<string[]>([]);
  const [nearPlacesList, setNearPlaceList] = useState<string[]>([]);
  const [optionList, setOptionList] = useState<AdOptionItem[]>([]);
  const descriptionValue = watch("description", "");
  const priceValue = watch("price", "");
  const titleValue = watch("title", "");
  const cityValue = watch("city", "");
  const districtValue = watch("district", "");
  const roomValue = watch("rooms", "");
  const hashtagsValue = watch("hashtags", "");
  const storeyValue = watch("storey", "");
  const floorsValue = watch("floors", "");
  const areaValue = watch("area", "");
  const repairmentValue = watch("repairment", "");
  const furnitureValue = watch("furniture", "");
  const addressValue = watch("address", "");
  const typeValue = watch("type", "");
  const [accordionExpanded, setAccordionExpanded] = useState<string | false>(
    false,
  );

  const {
    currency,
    nearbyPlaceData = [],
    fetchCurrency,
    fetchNearbyPlace,
  } = useUtilsStore();

  useEffect(() => {
    fetchCurrency();
    fetchNearbyPlace();
  }, [fetchCurrency, fetchNearbyPlace]);

  const onSubmit = () => {
    // const form = new FormData(e.target);
    // const data = Object.fromEntries(form);
    setIsLoading(true);
    const allValues = getValues();
    let photos = [];

    const upload = async () => {
      try {
        photos = await Promise.all(extFiles.map((e) => assetUpload(e.file)));

        // Server derives agentId/coworkerId from the auth token and logs the
        // AD_CREATED activity event itself — no separate statistics write needed.
        const { data: created } = await api.post("/ads", {
          ...allValues,
          nearPlacesList: nearPlacesList,
          optionList: optionList,
          photos,
          priceType,
        });

        // Attach anything published while this was still a draft to the ad.
        if (hasDraftPublications && created?.id) {
          try {
            await api.post("/publish/reassign", {
              fromAdId: draftAdId,
              toAdId: created.id,
            });
          } catch (e) {
            console.error("Could not link cross-posts to the new ad:", e);
          }
        }

        setIsLoading(false);

        navigate("/profile/" + id + "/ads");
      } catch (error) {
        console.error(error);
      }
    };
    toast.promise(upload, {
      error: "Something went wrong",
      pending: "Creating",
      success: "Successfully created",
    });
  };

  const updateFiles = (incommingFiles: ExtFile[]) => {
    console.log("incomming files", incommingFiles);
    setExtFiles(incommingFiles);
  };

  const updateFilesVideo = (incommingFiles: ExtFile[]) => {
    console.log("incomming files", incommingFiles);
    setExtFilesVideo(incommingFiles);
  };

  const onDelete = (id: ExtFile["id"]) => {
    setExtFiles(extFiles.filter((x) => x.id !== id));
  };
  const onDeleteVideo = (id: ExtFile["id"]) => {
    setExtFilesVideo(extFilesVideo.filter((x) => x.id !== id));
  };

  const handleSee = (imageSource: string | undefined) => {
    console.log("====================================");
    console.log({ imageSource });
    console.log("====================================");
    setImageSrc(imageSource);
  };

  const handleSeeVideo = (videoSource: string | undefined) => {
    setVideoSrc(videoSource);
  };

  const handleWatch = (videoSource: File | string | undefined) => {
    setVideoSrc(videoSource);
  };

  const handleAbort = (id: ExtFile["id"]) => {
    setExtFiles(
      extFiles.map((ef) => {
        if (ef.id === id) {
          return { ...ef, uploadStatus: "aborted" };
        } else return { ...ef };
      }),
    );
  };
  const handleAbortVideo = (id: ExtFile["id"]) => {
    setExtFilesVideo(
      extFilesVideo.map((ef) => {
        if (ef.id === id) {
          return { ...ef, uploadStatus: "aborted" };
        } else return { ...ef };
      }),
    );
  };
  const handleCancel = (id: ExtFile["id"]) => {
    setExtFiles(
      extFiles.map((ef) => {
        if (ef.id === id) {
          return { ...ef, uploadStatus: undefined };
        } else return { ...ef };
      }),
    );
  };
  const handleCancelVideo = (id: ExtFile["id"]) => {
    setExtFilesVideo(
      extFilesVideo.map((ef) => {
        if (ef.id === id) {
          return { ...ef, uploadStatus: undefined };
        } else return { ...ef };
      }),
    );
  };

  const handleSelectPlace = (text: string) => {
    let clone = [...nearPlacesList];
    if (clone.some((item) => item == text)) {
      clone.push(text);
      let filter = clone.filter((item) => item != text);
      setNearPlaceList(filter);
    } else {
      clone.push(text);
      setNearPlaceList(clone);
    }
  };

  const handleNewOption = (type: "add" | "remove", id?: number) => {
    let clone = [...optionList];
    if (type == "add") {
      clone.push({
        id: new Date().getTime(),
        key: "",
        value: "",
      });
      setOptionList([...clone]);
    } else if (type == "remove" && id) {
      let filter = clone.filter((item) => item.id != id);
      setOptionList([...filter]);
    }
  };

  const onSubmitTG = async () => {
    setIsLoading(true);

    const allValues = getValues();
    const photos = await Promise.all(extFiles.map((e) => assetUpload(e.file)));

    const caption = buildCaption(allValues, priceType, t, { hoistHashtags: true });

    const responses = await Promise.all(
      publishSelectSocial.map(async (socialItem) => {
        const formData = new FormData();
        formData.append("chat_id", String(socialItem.id));
        formData.append("protect_content", "true");
        formData.append(
          "media",
          JSON.stringify(
            photos.map((e, i) =>
              i === photos.length - 1
                ? {
                    type: "photo",
                    media: e,
                    caption: hashtagsValue + "\n" + caption,
                  }
                : { type: "photo", media: e },
            ),
          ),
        );

        try {
          const res = await axios.post(
            `https://api.telegram.org/bot${
              import.meta.env.VITE_TG_BOT_TOKEN
            }/sendMediaGroup`,
            formData,
          );

          setIsLoading(false);

          return res.data?.result[0];
        } catch (error) {
          console.error(error);
          return null;
        }
      }),
    );

    const successfulResponses = responses.filter(
      (response) => response !== null,
    );
    setResTg([...resTG, ...successfulResponses]);
  };
  const onSubmitIG = async () => {
    setIsLoading(true);
    const allValues = getValues();
    let photos: string[] = [];

    if (extFiles.length > 0) {
      photos = await Promise.all(extFiles.map((e) => assetUpload(e.file)));
    }

    const caption = buildCaption(allValues, priceType, t);

    try {
      // Publishing happens server-side with the stored token — no IG access
      // token ever reaches the browser.
      const igUserIds = publishSelectSocial
        .map((socialItem) => String(socialItem.igUserId ?? socialItem.id))
        .filter(Boolean);
      const { results } = await publishInstagramServerSide({
        adId: draftAdId,
        caption,
        imageUrls: photos,
        igUserIds,
      });
      setHasDraftPublications(true);
      const failed = results.filter((r) => !r.ok);
      if (failed.length) {
        toast.error(`Instagram publish failed for ${failed.map((f) => f.igUsername ?? f.igUserId).join(", ")}`);
      } else {
        toast.success("Instagram post published!");
      }
    } catch (error) {
      console.error("Error publishing posts:", error);
      toast.error(error?.response?.data?.error?.message ?? "Error publishing to Instagram");
    } finally {
      setIsLoading(false);
    }
  };

  // Extension-assisted path: opens OLX / Instagram in a new tab where the
  // La Casa extension autofills the post; the human reviews and clicks
  // Publish/Share there themselves.
  const onCrosspost = async (channel: "olx" | "instagram") => {
    if (!(await pingExtension())) {
      toast.error(
        "La Casa Cross-poster extension not detected. Install it, then reload this page — content scripts only load into tabs opened after the extension is installed.",
      );
      return;
    }
    if (channel === "instagram" && !currentUser?.igAssistConsentAt) {
      const agreed = window.confirm(
        "This fills your Instagram post (photos and an AI-written caption) inside your own browser. " +
          "You still review everything and click Share yourself — we never post on your behalf. " +
          "Using browser tools on Instagram carries some risk of a temporary review from Meta. Continue?",
      );
      if (!agreed) return;
      await grantIgAssistConsent();
      await fetchUserInfo();
    }
    setIsLoading(true);
    try {
      const photoUrls = await Promise.all(extFiles.map((e) => assetUpload(e.file)));
      const ad = { ...getValues(), priceType, nearPlacesList, optionList };
      const res = await requestCrosspost({ channel, adId: draftAdId, ad, photoUrls });
      if (res.ok) {
        setHasDraftPublications(true);
        toast.info("Opened a new tab — review the autofilled draft there and publish it yourself.");
      } else {
        toast.error(res.error ?? "The extension could not start the cross-post");
      }
    } catch (error) {
      toast.error(String(error?.message ?? error));
    } finally {
      setIsLoading(false);
    }
  };

  const onSubmitYT = async (event: React.MouseEvent<HTMLButtonElement>) => {
    event.preventDefault();
    setIsLoading(true);
    // let photos = [];

    // if (extFilesVideo.length > 0) {
    //   photos = await Promise.all(extFilesVideo.map((e) => assetUpload(e.file)));
    // }

    console.log(extFilesVideo);
    const metadata = {
      snippet: {
        title: "My Test Video",
        description: "This is a test upload using YouTube API.",
        tags: ["test", "YouTube API", "video"],
        categoryId: "22", // People & Blogs
      },
      status: {
        privacyStatus: "public", // or "private", "unlisted"
      },
    };
    await YTService.uploadVideo(
      extFilesVideo[0]?.file,
      metadata,
      (remainingTime, progress) => {
        console.log(`Time left: ${Math.round(remainingTime)}s`);
        console.log(`Progress: ${Math.round(progress)}%`);
      },
    );
  };

  const handleAccordionChange =
    (panel: string) => (event: React.SyntheticEvent, isExpanded: boolean) => {
      setAccordionExpanded(isExpanded ? panel : false);
    };

  const handleCheckboxChange = (item: SelectableSocialAccount) => {
    const socialKey = (x: SelectableSocialAccount) => x.igUserId ?? x.id;
    setPublishSelectSocial((prev) => {
      if (prev.some((social) => socialKey(social) === socialKey(item))) {
        return prev.filter((social) => socialKey(social) !== socialKey(item));
      }
      return [...prev, item];
    });
  };

  const handleCheckboxPhotoOrVideo = (checkedValue: string) => {
    setPhotoOrVideo((prevPhotos) => {
      if (prevPhotos.includes(checkedValue)) {
        return prevPhotos.filter((item) => item !== checkedValue);
      } else {
        return [...prevPhotos, checkedValue];
      }
    });
  };

  const handleChangeOption = (
    id: number,
    type: "key" | "value",
    value: string,
  ) => {
    let clone = [...optionList];
    let index = clone.findIndex((item) => item.id == id);
    clone[index] = { ...clone[index], [type]: value };
    setOptionList([...clone]);
  };

  const style = {
    position: "absolute",
    top: "50%",
    left: "50%",
    transform: "translate(-50%, -50%)",
    // width: 400,
    bgcolor: "background.paper",
    boxShadow: 24,
    p: 4,
  };

  if (isLoading) {
    return (
      <div className="loading">
        <Triangle
          visible={true}
          height="80"
          width="80"
          color="#4fa94d"
          ariaLabel="triangle-loading"
          wrapperStyle={{}}
          wrapperClass=""
        />
      </div>
    );
  }

  return (
    <div className="new-post-container">
      <div className="new-post-header">
        <h2>{t("addNewPost")}</h2>
      </div>
      <div>
        <div className="content">
          <div className="left">
            <div className="field">
              <label>{t("title")}</label>
              <input
                {...register("title", { required: "Title is required" })}
                placeholder="Enter post title"
                className={errors.title ? "error" : ""}
              />
              {errors.title && <span>{fieldErrorMessage(errors.title)}</span>}
            </div>
            <div className="field city">
              <div>
                <label htmlFor="city">{t("city")}</label>
                <select
                  name="city"
                  id="city"
                  {...register("city", {
                    required: "City is required",
                  })}
                  onChange={(e) =>
                    setRegionId(
                      regionData.regions.find((r) => r.name == e.target.value)
                        .id,
                    )
                  }
                  className={errors.city ? "error" : ""}
                >
                  <option key={"0"} value={""} defaultChecked></option>
                  {regionData.regions.map((region) => {
                    return (
                      <option
                        key={region.id.toString()}
                        value={region.name}
                        id={region.id.toString()}
                      >
                        {region.name}
                      </option>
                    );
                  })}
                </select>
                {errors.city && <span>{fieldErrorMessage(errors.city)}</span>}
              </div>
              <div>
                <label htmlFor="district">{t("district")}</label>
                <select
                  {...register("district", {
                    required: "District is required",
                  })}
                  name="district"
                  id="district"
                  disabled={regionId == 0}
                  className={errors.district ? "error" : ""}
                >
                  <option key={"0"} value={""} defaultChecked></option>
                  {regionData.districts
                    .filter((item) => item.region_id == regionId)
                    .map((district) => {
                      return (
                        <option
                          key={district.id.toString()}
                          value={district.name}
                        >
                          {district.name}
                        </option>
                      );
                    })}
                </select>
                {errors.district && <span>{fieldErrorMessage(errors.district)}</span>}
              </div>
            </div>
            <div className="field">
              <label>{t("address")}</label>
              <input
                {...register("address", { required: "Address is required" })}
                placeholder="Enter address"
                className={errors.title ? "error" : ""}
              />
              {errors.address && <span>{fieldErrorMessage(errors.address)}</span>}
            </div>
            <div className="field">
              <label>{t("orientation")}</label>
              <input
                {...register("reference", {
                  required: "Reference is required",
                })}
                placeholder="Enter reference"
                className={errors.reference ? "error" : ""}
              />
              {errors.reference && <span>{fieldErrorMessage(errors.reference)}</span>}
            </div>
            <div className="field city">
              <div>
                <label>{t("type")}</label>
                <select
                  {...register("type", {
                    required: "Type is required",
                  })}
                  name="type"
                >
                  <option value="residential" defaultChecked>
                    {t("residential")}
                  </option>
                  <option value="nonresidential">{t("nonresidential")}</option>
                </select>
                {errors.type && <span>{fieldErrorMessage(errors.type)}</span>}
              </div>
              <div>
                <label>{t("category")}</label>
                <select
                  {...register("category", {
                    required: "Category is required",
                  })}
                  name="category"
                >
                  <option value="rent">{t("rent")}</option>
                  <option value="sale">{t("sale")}</option>
                </select>
                {errors.category && <span>{fieldErrorMessage(errors.category)}</span>}
              </div>
            </div>
            <div className="field city">
              <div>
                <label htmlFor="repairment">{t("repair")}</label>
                <select
                  {...register("repairment", {
                    required: "Repairment is required",
                  })}
                  name="repairment"
                >
                  <option value="notRepaired" defaultChecked>
                    {t("requiresRepair")}
                  </option>
                  <option value="normal">{t("normal")}</option>
                  <option value="good">{t("good")}</option>
                  <option value="excellent">{t("excellent")}</option>
                </select>
                {errors.repairment && <span>{fieldErrorMessage(errors.repairment)}</span>}
              </div>
            </div>
            <div className="field city">
              <div>
                <label>{t("room_count")}</label>
                <input
                  {...register("rooms", {
                    required: "Rooms is required",
                  })}
                  placeholder="Enter rooms count"
                  className={errors.rooms ? "error" : ""}
                  type="number"
                />
                {errors.rooms && <span>{fieldErrorMessage(errors.rooms)}</span>}
              </div>
              <div>
                <label htmlFor="area">{t("totalArea")}</label>
                <input
                  {...register("area", {
                    required: "Area is required",
                  })}
                  id="area"
                  name="area"
                  type="number"
                  placeholder="Enter total area"
                />
                {errors.area && <span>{fieldErrorMessage(errors.area)}</span>}
              </div>
            </div>
            <div className="field city">
              <div>
                <label htmlFor="storey">{t("storey")}</label>
                <input
                  {...register("storey", {
                    required: "Storey is required",
                  })}
                  id="storey"
                  name="storey"
                  type="number"
                />
                {errors.storey && <span>{fieldErrorMessage(errors.storey)}</span>}
              </div>
              <div>
                <label htmlFor="floors">{t("floors")}</label>
                <input
                  {...register("floors", {
                    required: "Floors is required",
                  })}
                  id="floors"
                  name="floors"
                  type="number"
                />
                {errors.floors && <span>{fieldErrorMessage(errors.floors)}</span>}
              </div>
            </div>
            <div className="field city">
              <div>
                <label htmlFor="furniture">{t("furniture")}</label>
                <select
                  {...register("furniture", {
                    required: "Furniture is required",
                  })}
                  name="furniture"
                >
                  <option value="withFurniture">{t("withFurniture")}</option>
                  <option value="withoutFurniture">
                    {t("withoutFurniture")}
                  </option>
                </select>
                {errors.furniture && <span>{fieldErrorMessage(errors.furniture)}</span>}
              </div>
            </div>
            <div className="field">
              <label>{t("hashtags")}</label>
              <input
                {...register("hashtags", {})}
                placeholder={`${t("hashtags")}: #new #2024`}
                className={errors.hashtags ? "error" : ""}
              />
              {errors.hashtags && <span>{fieldErrorMessage(errors.hashtags)}</span>}
            </div>
            <div className="field price">
              <div>
                <label htmlFor="price">{t("price")}</label>
                <input
                  id="price"
                  type="number"
                  {...register("price", {
                    required: "Price is required",
                  })}
                />
                <i>
                  {convertDisplayPrice(priceValue, priceType, currency[0]?.currency)}
                </i>
                {errors.price && <span>{fieldErrorMessage(errors.price)}</span>}
              </div>
              <div className="priceType">
                <select
                  name="priceType"
                  onChange={(e) =>
                    setPriceType(e.target.value as CurrencyCodeKey)
                  }
                >
                  <option value="uzs" defaultChecked>
                    so&apos;m
                  </option>
                  <option value="usd">y.e</option>
                </select>
              </div>
            </div>
            <div className="field status">
              <div>
                <label htmlFor="stage">{t("status")}</label>
                <select
                  {...register("stage", {
                    required: "Status is required",
                  })}
                  name="stage"
                >
                  <option value="1">{t("active")}</option>
                  <option value="2">{t("sold")}</option>
                  <option value="3">{t("draft")}</option>
                </select>
                {errors.stage && <span>{fieldErrorMessage(errors.stage)}</span>}
              </div>
            </div>
          </div>
          <div className="right">
            <div className="field">
              <div className="placeList">
                <label htmlFor="description">{t("nearby")}</label>
                <div className="place-list">
                  {!!nearbyPlaceData.length &&
                    nearbyPlaceData[0]?.data?.map(
                      (item: string, index: number) => {
                      return (
                        <span
                          key={index.toString()}
                          onClick={() => handleSelectPlace(item)}
                          className={
                            nearPlacesList.some((place) => place == item)
                              ? "active"
                              : ""
                          }
                        >
                          {item}
                        </span>
                      );
                    })}
                </div>
              </div>
            </div>
            <div className="field">
              <div className="add-info">
                <label htmlFor="description">{t("additionalInfo")}</label>
                {optionList.map((item) => {
                  return (
                    <div key={item?.id.toString()}>
                      <input
                        placeholder="Title"
                        onChange={(e) =>
                          handleChangeOption(item.id, "key", e.target.value)
                        }
                        value={item?.key}
                      />
                      <input
                        placeholder="value"
                        onChange={(e) =>
                          handleChangeOption(item.id, "value", e.target.value)
                        }
                        value={item?.value}
                      />
                      <button
                        onClick={() => handleNewOption("remove", item.id)}
                        type="button"
                        className="delete-option"
                      >
                        {t("delete")}
                      </button>
                    </div>
                  );
                })}
                <button
                  type="button"
                  className="add-option"
                  onClick={() => handleNewOption("add")}
                >
                  {t("create")}
                </button>
              </div>
            </div>
            <div className="field">
              <label>{t("classification")}</label>
              <textarea
                name="description"
                placeholder="Примечания"
                {...register("description", {
                  required: "Description is required",
                })}
              ></textarea>
              {errors.description && <span>{fieldErrorMessage(errors.description)}</span>}
            </div>
            <div className="field photo">
              <label htmlFor="Images">{t("photo")}</label>
              <Dropzone
                onChange={updateFiles}
                minHeight="195px"
                value={extFiles}
                accept="image/*"
                maxFiles={5}
                maxFileSize={5 * 1024 * 1024}
                label={t("dragFilesHere")}
              >
                {extFiles.map((file) => (
                  <FileMosaic
                    {...file}
                    key={file.id}
                    onDelete={onDelete}
                    onSee={handleSee}
                    onWatch={handleWatch}
                    onAbort={handleAbort}
                    onCancel={handleCancel}
                    resultOnTooltip
                    alwaysActive
                    preview
                    info
                  />
                ))}
              </Dropzone>
              <FullScreen
                open={imageSrc !== undefined}
                onClose={() => setImageSrc(undefined)}
              >
                <ImagePreview src={imageSrc} />
              </FullScreen>
            </div>
            <div className="field photo">
              <label htmlFor="Videos">{t("video")}</label>
              <Dropzone
                onChange={updateFilesVideo}
                minHeight="195px"
                value={extFilesVideo}
                accept="video/*"
                maxFiles={1}
                maxFileSize={70 * 1024 * 1024}
                label={t("dragFilesHere")}
              >
                {extFilesVideo.map((file) => (
                  <FileMosaic
                    {...file}
                    key={file.id}
                    onDelete={onDeleteVideo}
                    onSee={handleSeeVideo}
                    onWatch={handleWatch}
                    onAbort={handleAbortVideo}
                    onCancel={handleCancelVideo}
                    resultOnTooltip
                    alwaysActive
                    preview
                    info
                  />
                ))}
              </Dropzone>
              <FullScreen
                open={videoSrc !== undefined}
                onClose={() => setVideoSrc(undefined)}
              >
                <VideoPreview src={videoSrc} />
              </FullScreen>
            </div>
          </div>
        </div>
        {!!currentUser.igAccounts && currentUser.igAccounts?.length >= 1 && (
          <Accordion
            expanded={accordionExpanded === "ig"}
            onChange={handleAccordionChange("ig")}
            sx={{ margin: "6px" }}
          >
            <AccordionSummary
              expandIcon={<ExpandIcon />}
              aria-controls="igbh-content"
              id="igbh-header"
            >
              <Avatar
                sx={{ width: 30, height: 30 }}
                src="https://static.cdnlogo.com/logos/i/93/instagram.svg"
              />
              <Typography variant="h5" sx={{ ml: 1 }}>
                Instagram
              </Typography>
            </AccordionSummary>
            <AccordionDetails className="ig-content-flex">
              <div className="ig-preview-container">
                <img src="/social-preview/iphone-bar.png" alt="" />
                <img src="/social-preview/ig-header.png" alt="" />
                <div className="ig-stories">
                  {currentUser.igAccounts?.map(
                    (e: InstagramAccount, index: number) => {
                    return (
                      <div key={index.toString()} className="igAvatar">
                        <img
                          src="/social-preview/gradient.svg"
                          className="ig-gradient"
                          alt=""
                        />
                        <Avatar
                          sx={{
                            width: 55,
                            height: 55,
                            margin: "12px",
                          }}
                          src={e.profile_picture_url}
                        />
                        <Typography
                          sx={{
                            fontSize: 12,
                            textAlign: "center",
                            fontWeight: "530",
                          }}
                        >
                          {e.username}
                        </Typography>
                      </div>
                    );
                  })}
                </div>
                <div className="ig-content">
                  <div
                    style={{
                      display: "flex",
                      flexDirection: "row",
                      alignItems: "center",
                      justifyContent: "space-between",
                    }}
                  >
                    <div className="ig-profile-container">
                      <Avatar
                        sx={{
                          width: 32,
                          height: 32,
                          margin: "12px",
                        }}
                        src={currentUser.igAccounts[0].profile_picture_url}
                      />
                      <div className="ig-profile-name">
                        <Typography
                          sx={{
                            fontSize: 12,
                            fontWeight: "600",
                          }}
                        >
                          {currentUser.igAccounts[0].username}
                        </Typography>
                        <Typography
                          sx={{
                            fontSize: 10,
                            fontWeight: "500",
                          }}
                        >
                          {cityValue}
                        </Typography>
                      </div>
                    </div>
                    <MoreHoriz />
                  </div>
                  <Carousel
                    indicatorContainerProps={{ style: { margin: "0" } }}
                    indicators
                    sx={{ height: "auto" }}
                  >
                    {[...extFiles, ...extFilesVideo].map((e, index) => {
                      if (
                        photoOrVideo.includes("photo") &&
                        e?.type.includes("image")
                      ) {
                        return (
                          <div
                            key={`photo-${index}`}
                            style={{ height: "400px" }}
                          >
                            <img
                              className="insta-post-img"
                              src={URL.createObjectURL(e.file)}
                              style={{
                                width: "100%",
                                height: "100%",
                                objectFit: "cover",
                              }}
                              alt={`photo-${index}`}
                            />
                          </div>
                        );
                      } else if (
                        photoOrVideo.includes("video") &&
                        e?.type?.includes("video")
                      ) {
                        return (
                          <div
                            key={`video-${index}`}
                            style={{ height: "400px" }}
                          >
                            <video
                              className="insta-post-video"
                              src={URL.createObjectURL(e.file)}
                              style={{
                                width: "100%",
                                height: "100%",
                                objectFit: "cover",
                              }}
                              muted
                              autoPlay
                              loop
                            />
                          </div>
                        );
                      }
                    })}
                  </Carousel>
                  <div className="post-footer">
                    <div className="post-icons">
                      <img
                        src="/social-preview/Снимок экрана 2024-11-09 в 00.52.25.png"
                        alt=""
                      />
                    </div>
                    <div className="post-text">
                      <span className="hashtags-text">{hashtagsValue}</span>
                      <b>142 likes</b>
                    </div>
                  </div>
                </div>
                <img
                  className="ig-iphone-bar"
                  src="/social-preview/ig-nav.png"
                  alt=""
                />
              </div>
              <div className="tg-btn-publish">
                <FormControlLabel
                  label="Photo"
                  control={
                    <Checkbox
                      onChange={() => handleCheckboxPhotoOrVideo("photo")}
                    />
                  }
                />
                <FormControlLabel
                  label="Video"
                  control={
                    <Checkbox
                      onChange={() => handleCheckboxPhotoOrVideo("video")}
                    />
                  }
                />
                <Button variant="contained" onClick={() => setOpenModal("ig")}>
                  {t("publish")}
                </Button>
              </div>
            </AccordionDetails>
          </Accordion>
        )}
        {(!currentUser.igAccounts || currentUser.igAccounts.length === 0) && (
          <Accordion
            expanded={accordionExpanded === "ig-assist"}
            onChange={handleAccordionChange("ig-assist")}
            sx={{ margin: "6px" }}
          >
            <AccordionSummary
              expandIcon={<ExpandIcon />}
              aria-controls="igbh-content"
              id="igbh-header"
            >
              <Avatar
                sx={{ width: 30, height: 30 }}
                src="https://static.cdnlogo.com/logos/i/93/instagram.svg"
              />
              <Typography variant="h5" sx={{ ml: 1 }}>
                Instagram
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <div className="tg-content-preview">
                <Typography sx={{ mb: 1 }}>
                  {t("igAssistHint", {
                    defaultValue:
                      "No Instagram account is connected. You can connect one in profile settings, or draft the post in your own browser with the La Casa extension — you review and click Share yourself.",
                  })}
                </Typography>
                <Button
                  variant="contained"
                  onClick={() => onCrosspost("instagram")}
                >
                  {t("publish")}
                </Button>
              </div>
            </AccordionDetails>
          </Accordion>
        )}
        {true && (
          <Accordion
            expanded={accordionExpanded === "fb"}
            onChange={handleAccordionChange("fb")}
            sx={{ margin: "6px" }}
          >
            <AccordionSummary
              expandIcon={<ExpandIcon />}
              aria-controls="igbh-content"
              id="igbh-header"
            >
              <Avatar
                sx={{ width: 30, height: 30 }}
                src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Facebook_Logo_2023.png/768px-Facebook_Logo_2023.png"
              />
              <Typography variant="h5" sx={{ ml: 1 }}>
                Facebook Market place
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <div className="tg-content-preview">
                <Button variant="contained" onClick={() => setOpenModal("yt")}>
                  Опубликовать
                </Button>
              </div>
            </AccordionDetails>
          </Accordion>
        )}
        {true && (
          <Accordion
            expanded={accordionExpanded === "yt"}
            onChange={handleAccordionChange("yt")}
            sx={{ margin: "6px" }}
          >
            <AccordionSummary
              expandIcon={<ExpandIcon />}
              aria-controls="igbh-content"
              id="igbh-header"
            >
              <Avatar
                sx={{ width: 30, height: 30 }}
                src="https://static.vecteezy.com/system/resources/previews/011/998/173/non_2x/youtube-icon-free-vector.jpg"
              />
              <Typography variant="h5" sx={{ ml: 1 }}>
                YouTube
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <div className="tg-content-preview">
                <YtVideoCard
                  hashtags={hashtagsValue}
                  title={titleValue}
                  isVideo={!!extFilesVideo[0]?.id}
                  bannerImg={
                    extFilesVideo.length > 0
                      ? URL.createObjectURL(extFilesVideo[0].file)
                      : ""
                  }
                  isShort={isShort}
                />
                <div className="tg-btn-publish">
                  <FormControlLabel
                    label="Short"
                    control={
                      <Checkbox onChange={() => setIsShort((prev) => !prev)} />
                    }
                  />
                  <Button
                    variant="contained"
                    type="button"
                    onClick={(event) => onSubmitYT(event)}
                  >
                    {t("publish")}
                  </Button>
                </div>
              </div>
            </AccordionDetails>
          </Accordion>
        )}
        {!!currentUser?.tgAccounts && currentUser.tgAccounts?.length >= 1 && (
          <Accordion
            expanded={accordionExpanded === "tg"}
            onChange={handleAccordionChange("tg")}
            sx={{ margin: "6px" }}
          >
            <AccordionSummary
              expandIcon={<ExpandIcon />}
              aria-controls="igbh-content"
              id="igbh-header"
            >
              <Avatar
                sx={{ width: 30, height: 30 }}
                src="https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Telegram_logo.svg/2048px-Telegram_logo.svg.png"
              />
              <Typography variant="h5" sx={{ ml: 1 }}>
                Telegram
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <div className="tg-content-preview">
                <div className="tg-content-flex">
                  <div className="tg-channel-logo">
                    <img src={currentUser?.tgAccounts[0].file_path} alt="" />
                  </div>
                  <div className="tg-post-content">
                    <div className="tg-post-header">
                      <h5>{currentUser?.tgAccounts[0].title}</h5>
                    </div>
                    <div className="tg-post-img-div">
                      <ImageGrid images={extFiles} />
                    </div>
                    <div className="tg-text-content">
                      <div className="tg-text-comment">
                        {!!hashtagsValue.length && (
                          <span className="hashtags-text">{hashtagsValue}</span>
                        )}
                        <h4>{titleValue}</h4>
                        <p>{descriptionValue}</p>
                        {!!priceValue.length && (
                          <p>
                            {t("price")}
                            {":"}
                            {priceValue}$
                          </p>
                        )}
                        {!!cityValue.length && (
                          <p>
                            {t("city")}
                            {": "} {cityValue}, {districtValue}
                          </p>
                        )}
                        {!!roomValue && (
                          <p>
                            {t("rooms")}
                            {": "} {roomValue}
                          </p>
                        )}
                        {!!storeyValue && (
                          <p>
                            {t("storey")}
                            {": "} {storeyValue}
                          </p>
                        )}
                        {!!floorsValue && (
                          <p>
                            {t("floors")}
                            {": "} {floorsValue}
                          </p>
                        )}
                        {!!areaValue && (
                          <p>
                            {t("area")}
                            {": "} {areaValue} m <sup>2</sup>
                          </p>
                        )}
                        {!!repairmentValue && (
                          <p>
                            {t("repairment")}
                            {": "} {repairmentValue}
                          </p>
                        )}
                        {!!furnitureValue && (
                          <p>
                            {t("furniture")}
                            {": "} {furnitureValue}
                          </p>
                        )}
                        {!!addressValue && (
                          <p>
                            {t("address")}
                            {": "} {addressValue}
                          </p>
                        )}
                        {!!typeValue && (
                          <p>
                            {t("type")}
                            {": "} {typeValue}
                          </p>
                        )}
                      </div>
                      <div className="tg-footer-text">
                        <a
                          href={`https://t.me/${currentUser?.tgAccounts[0].username}`}
                        >
                          t.me/{currentUser?.tgAccounts[0].username}
                        </a>
                        <div className="tg-createAt">
                          <span>12.7 K</span>
                          <span>
                            <VisibilityIcon sx={{ fontSize: "18px" }} />
                          </span>
                          <span>
                            {new Date().toLocaleDateString("en-US", {
                              year: "numeric",
                              month: "long",
                              day: "numeric",
                            })}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="tg-btn-publish">
                  <Button
                    variant="contained"
                    onClick={() => setOpenModal("tg")}
                  >
                    {t("publish")}
                  </Button>
                </div>
              </div>
            </AccordionDetails>
          </Accordion>
        )}
        {true && (
          <Accordion
            expanded={accordionExpanded === "olx"}
            onChange={handleAccordionChange("olx")}
            sx={{ margin: "6px" }}
          >
            <AccordionSummary
              expandIcon={<ExpandIcon />}
              aria-controls="igbh-content"
              id="igbh-header"
            >
              <Avatar
                sx={{ width: 30, height: 30 }}
                src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/2a/87/49/2a8749ed-07ce-0858-d259-840097d5caa8/AppIcon_OLX_EU-0-0-1x_U007emarketing-0-7-0-85-220.png/1200x630wa.png"
              />
              <Typography variant="h5" sx={{ ml: 1 }}>
                Olx
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <div className="tg-content-preview">
                <Typography sx={{ mb: 1 }}>
                  {t("olxAssistHint", {
                    defaultValue:
                      "Opens OLX.uz in a new tab and autofills the ad form from this listing (La Casa extension required). You review the draft and click Publish yourself.",
                  })}
                </Typography>
                <Button variant="contained" onClick={() => onCrosspost("olx")}>
                  {t("publish")}
                </Button>
              </div>
            </AccordionDetails>
          </Accordion>
        )}

        <div className="footer-new-post">
          <button type="button" onClick={onSubmit}>
            {t("create")}
          </button>
        </div>
      </div>

      <Modal
        open={
          openModal == "tg" ||
          openModal == "ig" ||
          openModal == "yt" ||
          openModal == "fb"
        }
        onClose={() => setOpenModal("")}
        aria-labelledby="modal-modal-title"
        aria-describedby="modal-modal-description"
      >
        <Box sx={style}>
          <div className="tg-channel-list">
            <h3>{t("select_channels")}</h3>
            {openModal == "ig" ? (
              <>
                <div className="tg-flex">
                  {!!currentUser.igAccounts &&
                    currentUser?.igAccounts?.map((e: InstagramAccount, index: number) => (
                      <div key={index} className="tg-channel-item-flex">
                        <IgProfileCard data={e} />
                        <Checkbox onChange={() => handleCheckboxChange(e)} />
                      </div>
                    ))}
                </div>
              </>
            ) : (
              <>
                <div className="tg-flex">
                  {currentUser?.tgAccounts?.length > 1 &&
                    currentUser?.tgAccounts?.map((item: ITGAccount, index: number) => {
                      return (
                        <div
                          key={index.toString()}
                          className="tg-channel-item-flex"
                        >
                          <TgProfileCard key={index} data={item} />
                          <Checkbox
                            onChange={() => handleCheckboxChange(item)}
                          />

                          {resTG.map((e) => {
                            if (e.chat.id == item.id) {
                              return (
                                <div
                                  key={e.message_id}
                                  onClick={() => {
                                    const url = `https://t.me/${item.username}/${e.message_id}`;
                                    navigator.clipboard
                                      .writeText(url)
                                      .then(() => {
                                        alert(
                                          "Link copied to clipboard: " + url,
                                        );
                                      })
                                      .catch((error) => {
                                        console.error(
                                          "Failed to copy text: ",
                                          error,
                                        );
                                      });
                                  }}
                                  className="tg-message-share-icon"
                                >
                                  <ShareIcon />
                                </div>
                              );
                            }
                          })}
                        </div>
                      );
                    })}
                </div>
              </>
            )}

            <Box sx={{ display: "flex", gap: "10px" }}>
              <Button
                onClick={() => {
                  setOpenModal("");
                  setPublishSelectSocial([]);
                }}
                variant="outlined"
                color="error"
              >
                {t("cancel")}
              </Button>
              <Button
                onClick={() => {
                  if (openModal == "ig") {
                    onSubmitIG();
                  } else if (openModal == "tg") {
                    onSubmitTG();
                  }
                }}
                variant="contained"
              >
                {t("publish")}
              </Button>
            </Box>
          </div>
        </Box>
      </Modal>
    </div>
  );
};

export default AdsAdd;
