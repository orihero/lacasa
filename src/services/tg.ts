import axios from "axios";

export interface ITGAccount {
  id: number | undefined;
  title: string;
  username: string;
  file_path?: string;
  members_count: number;
}

export class TGService {
  //@ts-ignore
  public static BOT_TOKEN = import.meta.env.VITE_TG_BOT_TOKEN;
  public static TgAccounts: ITGAccount[] = [];

  private static axiosInstance = axios.create({
    baseURL: `https://api.telegram.org/bot${this.BOT_TOKEN}`,
  });
  public static init = async (chats: number[]) => {
    try {
      const reses = chats.map((e) => this.getChatInfo(e));
      this.TgAccounts = await Promise.all(reses);
      return this.TgAccounts;
    } catch (error) {
      console.error(error);
    }
  };
  private static getChatInfo = async (chat_id: number): Promise<ITGAccount> => {
    //@ts-ignore
    let data: ITGAccount = {};
    try {
      const {
        data: {
          result: { title, username, id, photo },
        },
      } = await this.axiosInstance.get("/getChat", {
        params: { chat_id },
      });
      const {
        data: { result: members_count },
      } = await this.axiosInstance.get("/getChatMembersCount", {
        params: { chat_id },
      });
      if (!!photo) {
        const {
          data: {
            result: { file_path },
          },
        } = await this.axiosInstance.get("/getFile", {
          params: { file_id: photo.big_file_id },
        });
        data.file_path = `https://api.telegram.org/file/bot${this.BOT_TOKEN}/${file_path}`;
      }

      data = {
        ...data,
        id,
        members_count,
        title,
        username,
      };
    } catch (error) {
      throw new Error("Error getting telegram chatInfo", error);
    }
    return data as ITGAccount;
  };
}
