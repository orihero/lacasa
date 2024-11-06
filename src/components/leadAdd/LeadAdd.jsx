import React, { useState } from "react";
import "./leadAdd.scss";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { toast } from "react-toastify";
import { useUserStore } from "../../lib/userStore";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { db } from "../../lib/firebase";
import { useNavigate } from "react-router-dom";
const LeadAdd = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm();
  const { currentUser } = useUserStore();

  const onSubmit = async (data) => {
    console.log("Updated Data:", data);

    try {
      const newLead = {
        ...data,
        agentId: currentUser.id,
        coworkerId: 1,
        active: true,
        createdAt: serverTimestamp(),
      };

      await addDoc(collection(db, "leads"), newLead);

      toast.success("Lead successfully created!");
      reset();
      // navigate('/')
    } catch (error) {
      console.error("Error creating lead:", error);
      toast.error("Error creating lead: " + error.message);
    }
  };

  const handleCancel = () => {
    reset(); // Reset to initial values
  };

  return (
    <div className="profile-setting">
      <div className="profile-header">
        <h1>Create lead</h1>
      </div>
      <div className="profile-content">
        <div className="inputs">
          <form onSubmit={handleSubmit(onSubmit)}>
            <div className="field-list">
              <div className="field">
                <label>{t("fullName")}:</label>
                <input
                  type="text"
                  {...register("fullName", {
                    required: "First name is required",
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
                    required: "Phone number is required",
                    pattern: {
                      value: /^\+998\d{9}$/,
                      message: "Invalid Uzbekistan phone number",
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
                <label>{t("comment")}:</label>
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
            </div>

            <div className="profile-btns">
              <div className="buttons">
                <button
                  className="cancel-btn"
                  type="button"
                  onClick={handleCancel}
                >
                  Cancel
                </button>
                <button type="submit">Save</button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default LeadAdd;
