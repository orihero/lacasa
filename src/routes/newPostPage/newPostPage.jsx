import {
  Dropzone,
  FileMosaic,
  FullScreen,
  ImagePreview,
} from "@files-ui/react";
import "./newPostPage.scss";
import { useState } from "react";
import { addDoc, collection } from "firebase/firestore";
import { assetUpload } from "../../lib/assetUpload";
import { toast } from "react-toastify";
import { db } from "../../lib/firebase";
import axios from "axios";
import { useUserStore } from "../../lib/userStore";
import { IgService } from "../../services/ig";
import { useNavigate } from "react-router-dom";

const nearbyPlacesList = ["Park", "School", "Market", "City", "Kafe"];

function NewPostPage() {
  const [extFiles, setExtFiles] = useState([]);
  const [imageSrc, setImageSrc] = useState(undefined);
  const { currentUser } = useUserStore();
  const [nearPlacesList, setNearPlaceList] = useState([]);
  const [optionList, setOptionList] = useState([]);
  const navigate = useNavigate();

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
      })
    );
  };
  const handleCancel = (id) => {
    setExtFiles(
      extFiles.map((ef) => {
        if (ef.id === id) {
          return { ...ef, uploadStatus: undefined };
        } else return { ...ef };
      })
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
          active: true,
          optionList: optionList,
          photos,
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
                : { type: "photo", media: e }
            )
          )
        );
        const res = await axios.post(
          `https://api.telegram.org/bot${
            import.meta.env.VITE_TG_BOT_TOKEN
          }/sendMediaGroup`,
          form
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
      <div className="formContainer">
        <h1>Add New Post</h1>
        <div className="wrapper">
          <form onSubmit={onSubmit}>
            <label htmlFor="Images">Фото</label>
            <Dropzone
              onChange={updateFiles}
              minHeight="195px"
              value={extFiles}
              accept="image/*"
              maxFiles={5}
              maxFileSize={5 * 1024 * 1024}
              label="Перетащите файлы сюда или щелкните, чтобы загрузить"
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
              <label htmlFor="title">Название</label>
              <input id="title" name="title" type="text" />
            </div>
            <div className="item">
              <label htmlFor="city">Город</label>
              <input id="city" name="city" type="text" />
            </div>
            <div className="item">
              <label htmlFor="district">Район</label>
              <input id="district" name="district" type="text" />
            </div>
            <div className="item">
              <label htmlFor="address">Адрес</label>
              <input id="address" name="address" type="text" />
            </div>
            <div className="item">
              <label htmlFor="type">Тип</label>
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
              <label htmlFor="repairment">Ремонт</label>
              <select name="type">
                <option value="notRepaired" defaultChecked>
                  Требуется ремонт
                </option>
                <option value="normal">Нормальный</option>
                <option value="good">Хороший</option>
                <option value="excellent">Отличный</option>
              </select>
            </div>
            <div className="item">
              <label htmlFor="storey">Этаж</label>
              <input id="storey" name="storey" type="text" />
            </div>
            <div className="item">
              <label htmlFor="furniture">Мебель</label>
              <select name="type">
                <option value="withFurniture">С мебелью</option>
                <option value="withoutFurniture">Без мебели</option>
              </select>
            </div>
            <div className="item">
              <label htmlFor="area">Общая площадь</label>
              <input id="area" name="area" type="text" />
            </div>
            <div className="item">
              <label htmlFor="price">Цена</label>
              <input id="price" name="price" type="text" />
            </div>

            <div className="item placeList">
              <label htmlFor="description">Рядом есть</label>
              <div className="place-list">
                {nearbyPlacesList.map((item, index) => {
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
              <label htmlFor="description">Примечания</label>
              <textarea name="description" placeholder="Примечания"></textarea>
            </div>
            <div className="item add-info">
              <label htmlFor="description">Дополнительная информация</label>
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
                      удалить
                    </button>
                  </span>
                );
              })}
              <button
                type="button"
                className="add-option"
                onClick={() => handleNewOption("add")}
              >
                Добавлять
              </button>
            </div>
            <button className="sendButton">Add</button>
          </form>
        </div>
      </div>
      <div className="sideContainer"></div>
    </div>
  );
}

export default NewPostPage;
