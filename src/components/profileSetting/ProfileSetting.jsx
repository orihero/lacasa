import React, { useState } from "react";
import "./profileSetting.scss";
import { Avatar } from "@files-ui/react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import FormGroup from "@mui/material/FormGroup";
import FormControlLabel from "@mui/material/FormControlLabel";
import Switch from "@mui/material/Switch";
const ProfileSetting = () => {
  const { t } = useTranslation();
  const [profimeImage, setProfimeImage] = useState("/avatar.jpg");
  const [isEditing, setIsEditing] = useState(false);
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm({
    defaultValues: {
      avatar: "", // Here you can set default image URL if available
      firstName: "John",
      lastName: "Doe",
      phone: "+998901234567",
      email: "john.doe@example.com",
      password: "",
      confirmPassword: "",
    },
  });

  const onSubmit = (data) => {
    console.log("Updated Data:", data);
    setIsEditing(false);
  };

  const handleEdit = () => {
    setIsEditing(true);
  };

  const handleCancel = () => {
    reset(); // Reset to initial values
    setIsEditing(false);
  };

  return (
    <div className="profile-setting">
      <div className="profile-header">
        <h1>Profile Setting</h1>
      </div>
      <div className="profile-content">
        <div className="setting-left">2</div>
        <div className="setting-right">1</div>
      </div>
    </div>
  );
};

export default ProfileSetting;
