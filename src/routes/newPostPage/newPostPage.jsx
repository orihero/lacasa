import {
  Dropzone,
  FileMosaic,
  FullScreen,
  ImagePreview,
} from "@files-ui/react";
import "./newPostPage.scss";
import { useEffect, useState } from "react";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { assetUpload } from "../../lib/assetUpload";
import { toast } from "react-toastify";
import { db } from "../../lib/firebase";
import axios from "axios";
import { useUserStore } from "../../lib/userStore";
import { IgService } from "../../services/ig";
import { useNavigate } from "react-router-dom";
import { useUtilsStore } from "../../lib/utilsStore";
import regionData from "../../regions.json";
import { useTranslation } from "react-i18next";
import { ADS_TYPE } from "../../components/types/AdsType";

function NewPostPage() {
  const [extFiles, setExtFiles] = useState([]);
  const [imageSrc, setImageSrc] = useState(undefined);
  const { currentUser } = useUserStore();
  const [nearPlacesList, setNearPlaceList] = useState([]);
  const [optionList, setOptionList] = useState([]);
  const [price, setPrice] = useState(0);
  const [regionId, setRegionId] = useState(0);
  const [type, setType] = useState(0);
  const [priceType, setPriceType] = useState("uzs");
  const navigate = useNavigate();
  const { t } = useTranslation();
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

  const updateFiles = (incommingFiles) => {
    console.log("incomming files", incommingFiles);
    setExtFiles(incommingFiles);
  };
  const onDelete = (id) => {
    setExtFiles(extFiles.filter((x) => x.id !== id));
  };
  const handleSee = (imageSource) => {
    setImageSrc(imageSource);
  };
  const handleWatch = (videoSource) => {
    setVideoSrc(videoSource);
  };
  const handleStart = (filesToUpload) => {
    console.log("advanced demo start upload", filesToUpload);
  };
  const handleFinish = (uploadedFiles) => {
    console.log("advanced demo finish upload", uploadedFiles);
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

  const onSubmit = (e) => {
    e.preventDefault();
    const form = new FormData(e.target);
    const data = Object.fromEntries(form);
    let photos = [];
    let caption = "";

    // !Upload to IG
    const uploadIg = async () => {
      const res = await IgService.customCreateCarousel(photos, caption);
    };
    const upload = async () => {
      try {
        photos = await Promise.all(extFiles.map((e) => assetUpload(e.file)));

        await addDoc(collection(db, "ads"), {
          ...data,
          agentId: currentUser.id,
          nearPlacesList: nearPlacesList,
          active: type,
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

  const handleChangeOption = (id, key, text) => {
    let newArr = optionList.map((option) => {
      if (option.id == id) {
        if (key == "key") {
          return {
            ...option,
            key: text,
          };
        } else if (key == "value") {
          return {
            ...option,
            value: text,
          };
        }
      } else {
        return {
          ...option,
        };
      }
    });

    setOptionList([...newArr]);
  };

  return (
    <div className="newPostPage">
      <div className="content">
        <div className="formContainer">
          <h1>{t("addNewPost")}</h1>
          <div className="wrapper">
            <form onSubmit={onSubmit}>
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
              <div className="item">
                <label htmlFor="title">{t("title")}</label>
                <input id="title" name="title" type="text" />
              </div>
              <div className="item">
                <label htmlFor="city">{t("city")}</label>

                <select
                  name="city"
                  id="city"
                  onChange={(e) =>
                    setRegionId(
                      regionData.regions.find((r) => r.name == e.target.value)
                        .id,
                    )
                  }
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
              </div>
              <div className="item">
                <label htmlFor="district">{t("district")}</label>
                {/* <input id="district" name="district" type="text" /> */}
                <select name="district" id="district" disabled={regionId == 0}>
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
              </div>
              <div className="item">
                <label htmlFor="address">{t("address")}</label>
                <input id="address" name="address" type="text" />
              </div>
              <div className="item">
                <label htmlFor="type">{t("type")}</label>
                <select name="type">
                  <option value="residential" defaultChecked>
                    Жилое
                  </option>
                  <option value="nonresidential">Не Жилое</option>
                </select>
              </div>
              <div className="item">
                <label htmlFor="reference">Ориентир</label>
                <input id="reference" name="reference" type="text" />
              </div>
              <div className="item">
                <label htmlFor="rooms">Кол.комнат</label>
                <input id="rooms" name="rooms" type="text" />
              </div>
              <div className="item">
                <label htmlFor="repairment">{t("repair")}</label>
                <select name="repairment">
                  <option value="notRepaired" defaultChecked>
                    {t("requiresRepair")}
                  </option>
                  <option value="normal">Нормальный</option>
                  <option value="good">Хороший</option>
                  <option value="excellent">Отличный</option>
                </select>
              </div>
              <div className="item">
                <label>{t("category")}</label>
                <select name="category">
                  <option value="rent">{t("rental")}</option>
                  <option value="sale">Продажа</option>
                </select>
              </div>
              <div className="item storey">
                <span>
                  <label htmlFor="storey">{t("storey")}</label>
                  <input id="storey" name="storey" type="text" />
                </span>
                <span>
                  <label htmlFor="storeys">{t("floors")}</label>
                  <input id="storeys" name="storeys" type="text" />
                </span>
              </div>
              <div className="item">
                <label htmlFor="furniture">{t("furniture")}</label>
                <select name="furniture">
                  <option value="withFurniture">{t("withFurniture")}</option>
                  <option value="withoutFurniture">Без мебели</option>
                </select>
              </div>
              <div className="item">
                <label htmlFor="area">{t("totalArea")}</label>
                <input id="area" name="area" type="text" />
              </div>
              <div className="item price">
                <span className="price-span">
                  <label htmlFor="price">{t("price")}</label>
                  <input
                    id="price"
                    name="price"
                    type="number"
                    onChange={(e) => setPrice(e.target.value)}
                  />
                  <i>
                    {priceType == "uzs"
                      ? Math.floor(price / (currency[0]?.currency ?? 1)) + " $"
                      : (currency[0]?.currency ?? 0) * price + " so'm"}
                  </i>
                </span>
                <span>
                  <select
                    name="priceType"
                    onChange={(e) => setPriceType(e.target.value)}
                  >
                    <option value="uzs">so'm</option>
                    <option value="usd">y.e</option>
                  </select>
                </span>
              </div>

              <div className="item placeList">
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
              <div className="item description">
                <label htmlFor="description">{t("classification")}</label>
                <textarea
                  name="description"
                  placeholder="Примечания"
                ></textarea>
              </div>
              <div className="item add-info">
                <label htmlFor="description">{t("additionalInfo")}</label>
                {optionList.map((item) => {
                  return (
                    <span key={item?.id.toString()}>
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
                    </span>
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
              <div className="flex-btns">
                <button
                  className="sendButton"
                  onClick={() => setType(ADS_TYPE.DRAFT)}
                >
                  {t("save_draft")}
                </button>
                <button
                  className="sendButton"
                  onClick={() => setType(ADS_TYPE.ONLY_SOCIAL)}
                >
                  {t("upload_to_social_media")}
                </button>
                <button
                  className="sendButton"
                  onClick={() => setType(ADS_TYPE.ACTIVE)}
                >
                  {t("create")}
                </button>
              </div>
            </form>
          </div>
        </div>
        <div className="sideContainer"></div>
      </div>
    </div>
  );
}

export default NewPostPage;
