import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithEmailAndPassword,
} from "firebase/auth";
import { doc, setDoc } from "firebase/firestore";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import { auth, db } from "../../lib/firebase";
import "./register.scss";
import { useEffect, useState } from "react";
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
      const res = await createUserWithEmailAndPassword(auth, email, password);

      await setDoc(doc(db, "users", res.user.uid), {
        fullName,
        email,
        role: "user",
        phoneNumber,
        id: res.user.uid,
        password,
      });

      await signInWithEmailAndPassword(auth, email, password);
      fetchUserInfo(res.user.uid);
      fetchAdsList();

      toast.success("User successfully created");
      navigate("/");
      //TODO create user related data
    } catch (error) {
      console.error(Object.entries(error));
      console.error(error);
      toast.error(
        `Error
        ${error?.code}`,
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
