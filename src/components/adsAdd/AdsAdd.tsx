import React, { useEffect, useState } from "react";
import "./adsAdd.scss";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import regionData from "../../regions.json";
import { useUtilsStore } from "../../lib/utilsStore";
import ShareIcon from "@mui/icons-material/Share";
import {
  Dropzone,
  FileMosaic,
  FullScreen,
  ImagePreview,
} from "@files-ui/react";
import { toast } from "react-toastify";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { assetUpload } from "../../lib/assetUpload";
import axios from "axios";
import { db } from "../../lib/firebase";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Avatar,
  Paper,
  Typography,
} from "@mui/material";
import ExpandIcon from "@mui/icons-material/ExpandMore";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import { useUserStore } from "../../lib/userStore";
import Carousel from "react-material-ui-carousel";
import VisibilityIcon from "@mui/icons-material/Visibility";
import ImageGrid from "./components/ImageGrid";

const AdsAdd = () => {
  const {
    register,
    handleSubmit,
    formState: { errors },
    watch,
    getValues,
  } = useForm();
  const { t } = useTranslation();
  const { currentUser } = useUserStore();
  const [regionId, setRegionId] = useState(0);
  const [price, setPrice] = useState(0);
  const [extFiles, setExtFiles] = useState([]);
  const [imageSrc, setImageSrc] = useState(undefined);
  const [videoSrc, setVideoSrc] = useState(undefined);
  const [resTG, setResTg] = useState([]);
  const [priceType, setPriceType] = useState("uzs");
  const [nearPlacesList, setNearPlaceList] = useState([]);
  const [optionList, setOptionList] = useState([]);
  const descriptionValue = watch("description", "");
  const priceValue = watch("price", "");
  const titleValue = watch("title", "");
  const cityValue = watch("city", "");
  const districtValue = watch("district", "");
  const roomValue = watch("rooms", "");
  const categoryValue = watch("category", "");
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
  }, []);

  const onSubmit = (e) => {
    e.preventDefault();
    const form = new FormData(e.target);
    const data = Object.fromEntries(form);
    let photos = [];
    let caption = "";

    // !Upload to IG
    const uploadIg = async () => {
      const res = await IGService.customCreateCarousel(photos, caption);
    };
    const upload = async () => {
      try {
        photos = await Promise.all(extFiles.map((e) => assetUpload(e.file)));

        await addDoc(collection(db, "ads"), {
          ...data,
          agentId: currentUser.id,
          nearPlacesList: nearPlacesList,
          active: true,
          optionList: optionList,
          photos,
          createdAt: serverTimestamp(),
        });
      } catch (error) {
        console.error(error);
      }
      caption = Object.values(data).reduce((p, c) => p + c + "\n", "");
      try {
        await uploadIg();
      } catch (error) {
        console.error(error);
      }
      // !Upload to telegram
      try {
        const form = new FormData();
        form.append("chat_id", import.meta.env.VITE_LECASA_CHANNEL_ID);
        form.append("protect_content", "true");
        form.append(
          "media",
          JSON.stringify(
            photos.map((e, i) =>
              i == photos.length - 1
                ? { type: "photo", media: e, caption }
                : { type: "photo", media: e },
            ),
          ),
        );
        const res = await axios.post(
          `https://api.telegram.org/bot${
            import.meta.env.VITE_TG_BOT_TOKEN
          }/sendMediaGroup`,
          form,
        );
        console.error(res.data);
      } catch (error) {
        console.error(error);
      }
    };
    toast.promise(Promise.all(upload()), {
      error: "Something went wrong",
      pending: "Creating",
      success: "Successfully created",
    });
    navigate("/profile");
  };

  const updateFiles = (incommingFiles) => {
    console.log("incomming files", incommingFiles);
    setExtFiles(incommingFiles);
  };

  const onDelete = (id) => {
    setExtFiles(extFiles.filter((x) => x.id !== id));
  };
  const handleSee = (imageSource) => {
    console.log("====================================");
    console.log({ imageSource });
    console.log("====================================");
    setImageSrc(imageSource);
  };
  const handleWatch = (videoSource) => {
    setVideoSrc(videoSource);
  };

  const handleAbort = (id) => {
    setExtFiles(
      extFiles.map((ef) => {
        if (ef.id === id) {
          return { ...ef, uploadStatus: "aborted" };
        } else return { ...ef };
      }),
    );
  };
  const handleCancel = (id) => {
    setExtFiles(
      extFiles.map((ef) => {
        if (ef.id === id) {
          return { ...ef, uploadStatus: undefined };
        } else return { ...ef };
      }),
    );
  };

  const handleSelectPlace = (text) => {
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

  const handleNewOption = (type, id) => {
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

  const onSubmitTG = async (item) => {
    let photos = [];
    const allValues = getValues();
    const form = new FormData();
    photos = await Promise.all(extFiles.map((e) => assetUpload(e.file)));

    const caption = Object.entries(allValues).reduce(
      (result, [key, value]) =>
        result + `${t(key)}: ${value} ${key == "price" ? priceType : ""} \n`,
      "",
    );
    form.append("chat_id", item.id);
    form.append("protect_content", "true");
    form.append(
      "media",
      JSON.stringify(
        photos.map((e, i) =>
          i == photos.length - 1
            ? { type: "photo", media: e, caption }
            : { type: "photo", media: e },
        ),
      ),
    );
    const res = await axios
      .post(
        `https://api.telegram.org/bot${
          import.meta.env.VITE_TG_BOT_TOKEN
        }/sendMediaGroup`,
        form,
      )
      .catch((error) => console.error(error));
    console.error(res.data);
    let cloneRes = [...resTG];
    cloneRes.push(res.data?.result[0]);
    setResTg([...cloneRes]);
  };

  const handleAccordionChange =
    (panel: string) => (event: React.SyntheticEvent, isExpanded: boolean) => {
      setAccordionExpanded(isExpanded ? panel : false);
    };

  return (
    <div className="new-post-container">
      <div className="new-post-header">
        <h2>Add New Post</h2>
      </div>
      <form onSubmit={handleSubmit(onSubmit)}>
        <div className="content">
          <div className="left">
            <div className="field">
              <label>{t("title")}</label>
              <input
                {...register("title", { required: "Title is required" })}
                placeholder="Enter post title"
                className={errors.title ? "error" : ""}
              />
              {errors.title && <span>{errors.title.message}</span>}
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
                  {regionData.regions.map((region, i) => {
                    return (
                      <option
                        key={region.id.toString()}
                        value={region.name}
                        id={region.id}
                      >
                        {region.name}
                      </option>
                    );
                  })}
                </select>
                {errors.city && <span>{errors.city.message}</span>}
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
                    .map((district, i) => {
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
                {errors.district && <span>{errors.district.message}</span>}
              </div>
            </div>
            <div className="field">
              <label>{t("address")}</label>
              <input
                {...register("address", { required: "Address is required" })}
                placeholder="Enter address"
                className={errors.title ? "error" : ""}
              />
              {errors.address && <span>{errors.address.message}</span>}
            </div>
            <div className="field">
              <label>Ориентир</label>
              <input
                {...register("reference", {
                  required: "Reference is required",
                })}
                placeholder="Enter reference"
                className={errors.reference ? "error" : ""}
              />
              {errors.reference && <span>{errors.reference.message}</span>}
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
                    Жилое
                  </option>
                  <option value="nonresidential">Не Жилое</option>
                </select>
                {errors.type && <span>{errors.type.message}</span>}
              </div>
              <div>
                <label>{t("category")}</label>
                <select
                  {...register("category", {
                    required: "Category is required",
                  })}
                  name="category"
                >
                  <option value="rent">{t("rental")}</option>
                  <option value="sale">Продажа</option>
                </select>
                {errors.category && <span>{errors.category.message}</span>}
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
                  <option value="normal">Нормальный</option>
                  <option value="good">Хороший</option>
                  <option value="excellent">Отличный</option>
                </select>
                {errors.repairment && <span>{errors.repairment.message}</span>}
              </div>
            </div>
            <div className="field city">
              <div>
                <label>Кол.комнат</label>
                <input
                  {...register("rooms", {
                    required: "Rooms is required",
                  })}
                  placeholder="Enter rooms count"
                  className={errors.rooms ? "error" : ""}
                  type="number"
                />
                {errors.rooms && <span>{errors.rooms.message}</span>}
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
                {errors.area && <span>{errors.area.message}</span>}
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
                {errors.storey && <span>{errors.storey.message}</span>}
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
                {errors.floors && <span>{errors.floors.message}</span>}
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
                  <option value="withoutFurniture">Без мебели</option>
                </select>
                {errors.furniture && <span>{errors.furniture.message}</span>}
              </div>
            </div>
            <div className="field price">
              <div>
                <label htmlFor="price">{t("price")}</label>
                <input
                  id="price"
                  name="price"
                  type="number"
                  onChange={(e) => setPrice(e.target.value)}
                  {...register("price", {
                    required: "Price is required",
                  })}
                />
                <i>
                  {priceType == "uzs"
                    ? Math.floor(price / (currency[0]?.currency ?? 1)) + " $"
                    : (currency[0]?.currency ?? 0) * price + " so'm"}
                </i>
                {errors.price && <span>{errors.price.message}</span>}
              </div>
              <div className="priceType">
                <select
                  name="priceType"
                  onChange={(e) => setPriceType(e.target.value)}
                >
                  <option value="uzs" defaultChecked>
                    so'm
                  </option>
                  <option value="usd">y.e</option>
                </select>
              </div>
            </div>
          </div>
          <div className="right">
            <div className="field">
              <div className="placeList">
                <label htmlFor="description">{t("nearby")}</label>
                <div className="place-list">
                  {!!nearbyPlaceData.length &&
                    nearbyPlaceData[0]?.data?.map((item, index) => {
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
              {errors.description && <span>{errors.description.message}</span>}
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
            <AccordionDetails>
              <div className="ig-preview-container">
                <img src="/social-preview/iphone-bar.png" alt="" />
                <img src="/social-preview/ig-header.png" alt="" />
                <div className="ig-stories">
                  {currentUser.igAccounts?.map((e) => {
                    return (
                      <div className="igAvatar">
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
                          {document.getElementById("city")?.value}
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
                    {extFiles.map((e) => {
                      return (
                        <div style={{ height: "400px" }}>
                          <img
                            className="insta-post-img"
                            src={URL.createObjectURL(e.file)}
                          />
                        </div>
                      );
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
            </AccordionDetails>
          </Accordion>
        )}
        {!!currentUser.tgChatIds &&
          !!currentUser.tgAccounts &&
          currentUser.tgChatIds?.length >= 1 && (
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
                        {!!categoryValue.length && (
                          <span>#{categoryValue}</span>
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
                            <VisibilityIcon fontSize="18px" />
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
                  <div className="tg-channel-list">
                    {currentUser?.tgAccounts.length > 1 &&
                      currentUser?.tgAccounts.map((item) => {
                        return (
                          <>
                            <div
                              onClick={() => onSubmitTG(item)}
                              className="tg-channel-item"
                            >
                              <img src={item.file_path} alt="" />
                              <p>{item.title}</p>
                            </div>
                            {resTG.map((e) => {
                              if (e.chat.id == item.id) {
                                return (
                                  <div
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
                          </>
                        );
                      })}
                  </div>
                </div>
              </AccordionDetails>
            </Accordion>
          )}
        <div className="footer-new-post">
          <button type="submit">{t("create")}</button>
        </div>
      </form>
    </div>
  );
};

export default AdsAdd;
