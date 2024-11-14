import React, { useEffect, useState } from "react";
import "./leadAdd.scss";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { toast } from "react-toastify";
import { useUserStore } from "../../lib/userStore";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { db } from "../../lib/firebase";
import { useNavigate, useParams } from "react-router-dom";
import { Triangle } from "react-loader-spinner";
import { useCoworkerStore } from "../../lib/useCoworkerStore";
const LeadAdd = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { fetchCoworkerList, list } = useCoworkerStore();
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm();
  const { currentUser } = useUserStore();
  const [loading, setLoading] = useState(false);
  const { id } = useParams();

  useEffect(() => {
    if (id) {
      fetchCoworkerList(id);
    }
  }, [id]);

  const onSubmit = async (data) => {
    setLoading(true);
    try {
      const newLead = {
        ...data,
        agentId:
          currentUser.role == "agent" ? currentUser.id : currentUser.agentId,
        active: true,
        createdAt: serverTimestamp(),
      };

      if (currentUser.role == "coworker") {
        newLead["coworkerId"] = currentUser.id;
      }

      await addDoc(collection(db, "leads"), newLead);

      toast.success("Lead successfully created!");
      reset();
      navigate("/profile/" + currentUser.id + "/leads");
    } catch (error) {
      console.error("Error creating lead:", error);
      toast.error("Error creating lead: " + error.message);
    }
    setLoading(false);
  };

  const handleCancel = () => {
    reset(); // Reset to initial values
    navigate("/profile/" + id + "/leads");
  };

  if (loading) {
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
    <div className="profile-setting-add">
      <div className="profile-header">
        <h1>{t("createLead")}</h1>
      </div>
      <div className="profile-content-add">
        <div className="inputs-add">
          <form onSubmit={handleSubmit(onSubmit)}>
            <div className="field-list-add">
              <div className="field">
                <label>{t("fullName")}:</label>
                <input
                  type="text"
                  {...register("fullName", {
                    required: t("firstNameRequired"),
                  })}
                  className={errors.fullName ? "error" : ""}
                />
                {errors.fullName && <span>{errors.fullName.message}</span>}
              </div>
              <div className="field">
                <label>{t("phone")}:</label>
                <input
                  type="text"
                  {...register("phone", {
                    required: t("phoneNumberRequired"),
                    pattern: {
                      value: /^\+998\d{9}$/,
                      message: t("invalidUzbekistanPhoneNumber"),
                    },
                  })}
                  className={errors.phone ? "error" : ""}
                />
                {errors.phone && <span>{errors.phone.message}</span>}
              </div>
              <div className="field">
                <label>{t("email")}:</label>
                <input type="email" {...register("email", {})} />
              </div>
              <div className="field">
                <label>{t("budget")}:</label>
                <input type="text" {...register("budget", {})} />
              </div>
              <div className="field">
                <label>{t("commit")}:</label>
                <textarea {...register("comment", {})}></textarea>
              </div>
              <div className="field">
                <label>{t("status")}:</label>
                <select name="status" {...register("status")}>
                  <option value="new">{t("new")}</option>
                  <option value="could_not_connect">
                    {t("could_not_connect")}
                  </option>
                  <option value="need_to_call_back">
                    {t("need_to_call_back")}
                  </option>
                  <option value="rejected">{t("rejected")}</option>
                  <option value="accepted">{t("accepted")}</option>
                </select>
              </div>
              <div className="field">
                <label>{t("source")}:</label>
                <input type="text" {...register("source", {})} />
              </div>
              {currentUser.role == "agent" && (
                <div className="field">
                  <label>{t("coworker")}:</label>
                  <select name="coworkerId" {...register("coworkerId")}>
                    <option value={"0"}></option>;
                    {list?.map((item) => {
                      return <option value={item?.id}>{item?.fullName}</option>;
                    })}
                  </select>
                </div>
              )}
            </div>

            <div className="profile-btns">
              <div className="buttons">
                <button
                  className="cancel-btn"
                  type="button"
                  onClick={handleCancel}
                >
                  {t("cancel")}
                </button>
                <button type="submit">{t("save")}</button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default LeadAdd;
