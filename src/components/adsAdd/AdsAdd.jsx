import React, { useEffect, useState } from "react";
import "./adsAdd.scss";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import regionData from "../../regions.json";
import { useUtilsStore } from "../../lib/utilsStore";
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

const AdsAdd = () => {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm();
  const { t } = useTranslation();
  const [regionId, setRegionId] = useState(0);
  const [price, setPrice] = useState(0);
  const [extFiles, setExtFiles] = useState([]);
  const [imageSrc, setImageSrc] = useState(undefined);
  const [priceType, setPriceType] = useState("uzs");
  const [nearPlacesList, setNearPlaceList] = useState([]);
  const [optionList, setOptionList] = useState([]);
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
      const res = await IgService.customCreateCarousel(photos, caption);
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
        <div className="footer-new-post">
          <button type="submit">{t("create")}</button>
        </div>
      </form>
    </div>
  );
};

export default AdsAdd;
