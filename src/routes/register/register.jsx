import { createUserWithEmailAndPassword } from "firebase/auth";
import { doc, setDoc } from "firebase/firestore";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import { auth, db } from "../../lib/firebase";
import "./register.scss";

function Register() {
  const navigate = useNavigate();
  const handleRegister = async (e) => {
    e.preventDefault();

    const formData = new FormData(e.target);
    const { fullName, email, password, phoneNumber } =
      Object.fromEntries(formData);

    try {
      const res = await createUserWithEmailAndPassword(auth, email, password);

      const docRef = await setDoc(doc(db, "users", res.user.uid), {
        fullName,
        email,
        role: "user",
        phoneNumber,
        id: res.user.uid,
      });

      toast.success("User successfully created");
      navigate("/profile");
      //TODO create user related data
    } catch (error) {
      console.error(Object.entries(error));
      console.error(error);
      toast.error(
        `Error
        ${error?.code}`,
      );
    }
  };

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
