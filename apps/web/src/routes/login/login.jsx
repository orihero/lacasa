import "./login.scss";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import { api, setAuthToken } from "../../lib/api";
import { useUserStore } from "../../lib/userStore";

function Login() {
  const navigate = useNavigate();
  const { fetchUserInfo } = useUserStore();

  const handleLogin = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const { email, password } = Object.fromEntries(formData);

    try {
      const { data } = await api.post("/auth/login", { email, password });
      setAuthToken(data.token);
      await fetchUserInfo();

      toast.success("User successfully logged in");
      navigate("/");
    } catch (error) {
      console.error(error);
      toast.error(
        `Error
        ${error?.response?.data?.error?.message ?? error.message}`,
      );
    }
  };

  return (
    <div className="login">
      <div className="formContainer">
        <form onSubmit={handleLogin}>
          <h1>Welcome back</h1>
          <input required name="email" type="text" placeholder="Email" />
          <input
            required
            name="password"
            type="password"
            placeholder="Password"
          />
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
