import axios from "axios";

export interface ITGAccount {
  id?: number;
  title?: string;
  username?: string;
  file_path?: string;
  members_count?: number;
}

export class TGService {
  public static BOT_TOKEN: string | undefined = import.meta.env
    .VITE_TG_BOT_TOKEN;
  public static TgAccounts: ITGAccount[] = [];

  private static axiosInstance = axios.create({
    baseURL: `https://api.telegram.org/bot${import.meta.env.VITE_TG_BOT_TOKEN}`,
  });

  // Initialize Telegram service with chat IDs
  public static init = async (chats: number[]): Promise<ITGAccount[]> => {
    try {
      if (!this.BOT_TOKEN) {
        throw new Error("Telegram BOT_TOKEN is not defined");
      }

      const chatInfoPromises = chats.map((chatId) =>
        this.getChatInfo(chatId).catch((error) => {
          console.error(
            `Failed to fetch chat info for chat ID ${chatId}:`,
            error,
          );
          return null; // Skip failed chat info
        }),
      );

      const resolvedChatInfo = await Promise.all(chatInfoPromises);
      this.TgAccounts = resolvedChatInfo.filter(
        (account): account is ITGAccount => account !== null,
      );

      return this.TgAccounts;
    } catch (error) {
      console.error("Error initializing Telegram service:", error);
      return [];
    }
  };

  // Get chat information
  private static getChatInfo = async (chat_id: number): Promise<ITGAccount> => {
    const data: ITGAccount = {};

    try {
      // Fetch basic chat info
      const chatInfoResponse = await this.axiosInstance.get("/getChat", {
        params: { chat_id },
      });

      const {
        result: { title, username, id, photo },
      } = chatInfoResponse.data;

      data.title = title;
      data.username = username;
      data.id = id;

      // Fetch chat member count
      const memberCountResponse = await this.axiosInstance.get(
        "/getChatMembersCount",
        {
          params: { chat_id },
        },
      );
      data.members_count = memberCountResponse.data.result;

      // Fetch chat photo if it exists
      if (photo?.big_file_id) {
        const fileResponse = await this.axiosInstance.get("/getFile", {
          params: { file_id: photo.big_file_id },
        });

        const filePath = fileResponse.data.result.file_path;
        if (filePath) {
          data.file_path = `https://api.telegram.org/file/bot${this.BOT_TOKEN}/${filePath}`;
        }
      }
    } catch (error) {
      console.error(
        `Error getting Telegram chat info for chat ID ${chat_id}:`,
        error,
      );
      throw new Error("Error fetching chat info");
    }

    return data;
  };
}
