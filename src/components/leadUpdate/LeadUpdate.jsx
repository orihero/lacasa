import React, { useEffect, useState } from "react";
import "./leadUpdate.scss";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { toast } from "react-toastify";
import { useUserStore } from "../../lib/userStore";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  serverTimestamp,
  updateDoc,
} from "firebase/firestore";
import { db } from "../../lib/firebase";
import { useNavigate, useParams } from "react-router-dom";
import { Triangle } from "react-loader-spinner";
import { useCoworkerStore } from "../../lib/useCoworkerStore";
import { useLeadStore } from "../../lib/useLeadStore";
const LeadUpdate = ({ leadId, onClose }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { fetchCoworkerList, list } = useCoworkerStore();
  const { fetchLeadById, lead, isLoading } = useLeadStore();
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    watch,
  } = useForm({});
  const { currentUser } = useUserStore();
  const [loading, setLoading] = useState(false);
  // const [selectValue, setSelectValue] = useState("");
  const { id } = useParams();
  const statusValue = watch("status", "new");
  useEffect(() => {
    if (currentUser?.id && currentUser.role == "agent") {
      fetchCoworkerList(currentUser.id);
    }
  }, [currentUser.id]);

  useEffect(() => {
    if (leadId) {
      fetchLeadById(leadId);
    }
  }, [leadId]);

  useEffect(() => {
    if (lead) {
      reset({
        fullName: lead.fullName || "",
        email: lead.email || "",
        phone: lead.phone || "",
        budget: lead.budget || "",
        comment: lead.comment || "",
        status: lead.status || "",
        source: lead.source || "",
        callbackDate: lead?.callbackDate || "",
        coworkerId: lead.coworkerId || "",
      });
    }
  }, [lead]);

  const onSubmit = async (data) => {
    setLoading(true);
    try {
      const updatedLead = {
        ...data,
        updatedAt: serverTimestamp(),
      };

      const leadRef = doc(db, "leads", leadId);
      await updateDoc(leadRef, updatedLead);

      toast.success("Lead successfully updated!");
      reset();
      // navigate("/profile/" + currentUser.id + "/leads");
      onClose();
    } catch (error) {
      console.error("Error updating lead:", error);
      toast.error("Error updating lead: " + error?.message);
    }
    setLoading(false);
  };

  const handleDelete = async () => {
    setLoading(true);
    try {
      const leadRef = doc(db, "leads", leadId);
      await deleteDoc(leadRef);

      toast.success("Lead successfully deleted!");
      navigate("/profile/" + currentUser.id + "/leads");
    } catch (error) {
      console.error("Error deleting lead:", error);
      toast.error("Error deleting lead: " + error?.message);
    }
    setLoading(false);
  };

  const handleCancel = () => {
    reset(); // Reset to initial values
    onClose();
  };

  if (loading || isLoading) {
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
    <div className="profile-setting-update">
      <div className="profile-header">
        <h1>Update lead</h1>
      </div>
      <div className="profile-content-update">
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
              {statusValue == "need_to_call_back" && (
                <div className="field">
                  <label>{t("qo'ng'iroq qilish vaqti")}:</label>
                  <input
                    type="datetime-local"
                    {...register("callbackDate")}
                    placeholder={t("select_date")}
                  />
                </div>
              )}
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
                      return (
                        <option
                          key={item.id}
                          value={item?.id}
                          defaultChecked={item?.id == lead?.coworkerId}
                        >
                          {item?.fullName}
                        </option>
                      );
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
                  Cancel
                </button>
                <button type="submit">Save</button>
                <button
                  className="delete-btn"
                  type="button"
                  onClick={handleDelete}
                >
                  Delete
                </button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default LeadUpdate;
