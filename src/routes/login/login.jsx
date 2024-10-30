import { signInWithEmailAndPassword } from "firebase/auth";
import "./login.scss";
import { Link, useNavigate } from "react-router-dom";
import { auth } from "../../lib/firebase";
import { toast } from "react-toastify";

function Login() {
  const navigate = useNavigate();
  const handleLogin = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const { email, password } = Object.fromEntries(formData);

    try {
      await signInWithEmailAndPassword(auth, email, password);
      toast.success("User successfully logged in");
      navigate("/profile");
    } catch (error) {
      console.error(Object.entries(error));
      toast.error(
        `Error
        ${error?.code}`,
      );
    }
  };

  return (
    <div className="login">
      <div className="formContainer">
        <form onSubmit={handleLogin}>
          <h1>Welcome back</h1>
          <input name="email" type="text" placeholder="Email" />
          <input name="password" type="password" placeholder="Password" />
          <button>Login</button>
          <Link to="/register">{"Don't"} you have an account?</Link>
        </form>
      </div>
      <div className="imgContainer">
        <img src="/bg.png" alt="" />
      </div>
    </div>
  );
}

export default Login;
