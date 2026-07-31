import { Link, useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import { api, setAuthToken } from "../../lib/api";
import "./register.scss";
import { useState } from "react";
import { Triangle } from "react-loader-spinner";
import { useUserStore } from "../../lib/userStore";
import { useListStore } from "../../lib/adsListStore";

function Register() {
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(false);
  const { fetchUserInfo } = useUserStore();
  const { fetchAdsList } = useListStore();
  const handleRegister = async (e) => {
    setIsLoading(true);
    e.preventDefault();

    const formData = new FormData(e.target);
    const { fullName, email, password, phoneNumber } =
      Object.fromEntries(formData);

    try {
      const { data } = await api.post("/auth/register", {
        fullName,
        email,
        password,
        phoneNumber,
      });
      setAuthToken(data.token);
      await fetchUserInfo();
      fetchAdsList();

      toast.success("User successfully created");
      navigate("/");
    } catch (error) {
      console.error(error);
      toast.error(
        `Error
        ${error?.response?.data?.error?.message ?? error.message}`,
      );
    }

    setIsLoading(false);
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
    <div className="register">
      <div className="formContainer">
        <form onSubmit={handleRegister}>
          <h1>Create an Account</h1>
          <input required name="fullName" type="text" placeholder="Full name" />
          <input
            required
            name="phoneNumber"
            type="tel"
            placeholder="Phone number"
          />
          <input required name="email" type="text" placeholder="Email" />
          <input
            required
            name="password"
            type="password"
            placeholder="Password"
          />
          <button>Register</button>
          <Link to="/login">Do you have an account?</Link>
        </form>
      </div>
      <div className="imgContainer">
        <img src="/bg.png" alt="" />
      </div>
    </div>
  );
}

export default Register;
