import Paper from "@mui/material/Paper";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableContainer from "@mui/material/TableContainer";
import TableHead from "@mui/material/TableHead";
import TablePagination from "@mui/material/TablePagination";
import TableRow from "@mui/material/TableRow";
import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import EditIcon from "../../components/icons/EditIcon";
import { formatCreatedAt } from "../../hooks/formatDate";
import { useListStore } from "../../lib/adsListStore";
import { useUserStore } from "../../lib/userStore";
import "./adsList.scss";

const AdsList = () => {
  const { myList } = useListStore();
  const { currentUser } = useUserStore();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const columns = [
    { id: "id", label: t("id"), minWidth: 50 },
    {
      id: "photos",
      label: t("photo"),
      minWidth: 80,
      format: (value) => value[0],
    },
    {
      id: "createdAt",
      label: t("createdAt"),
      minWidth: 100,
      format: (value) => formatCreatedAt(value),
    },
    {
      id: "city",
      label: t("city"),
      minWidth: 170,
      align: "left",
      format: (value) => value,
    },
    {
      id: "status",
      label: t("status"),
      minWidth: 170,
      align: "left",
      format: (value) => value.toLocaleString("en-US"),
    },
    {
      id: "author",
      label: t("author"),
      minWidth: 120,
      align: "left",
      format: (value) => value.toFixed(2),
    },
    {
      id: "rooms",
      label: t("room"),
      minWidth: 60,
      align: "center",
      format: (value) => value.toFixed(2),
    },
    {
      id: "area",
      label: t("totalArea"),
      minWidth: 70,
      align: "center",
      format: (value) => value.toFixed(2),
    },
    {
      id: "edit",
      label: "",
      minWidth: 60,
      align: "right",
    },
  ];

  const [page, setPage] = React.useState(0);
  const [rowsPerPage, setRowsPerPage] = React.useState(10);

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(+event.target.value);
    setPage(0);
  };

  const handleDeleteEdit = (id) => {
    navigate("/profile/" + id + "/update/ads");
  };

  const handleNavigate = (id) => {
    navigate("/post/" + id);
  };

  const handleNewPost = () => {
    navigate("/profile/" + currentUser.id + "/create/ads");
  };

  return (
    <div className="ads-list-content">
      {/* <div className="filter-tools">filter</div> */}
      <div className="ads-new">
        <button onClick={handleNewPost}>{t("createNewPost")}</button>
      </div>
      <Paper sx={{ width: "100%", overflow: "hidden" }}>
        <TableContainer sx={{ maxHeight: 580 }}>
          <Table stickyHeader aria-label="sticky table">
            <TableHead>
              <TableRow>
                {columns.map((column) => (
                  <TableCell
                    key={column.id}
                    align={column.align}
                    style={{ minWidth: column.minWidth }}
                  >
                    {column.label}
                  </TableCell>
                ))}
              </TableRow>
            </TableHead>
            <TableBody>
              {[...myList]
                ?.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                .map((row) => {
                  return (
                    <TableRow
                      hover
                      role="checkbox"
                      tabIndex={-1}
                      key={row.code}
                    >
                      {columns.map((column) => {
                        const value = row[column.id];
                        if (column.id == "edit") {
                          return (
                            <TableCell key={column.id} align={column.align}>
                              <div className="icons">
                                <span
                                  style={{ padding: "8px", cursor: "pointer" }}
                                  onClick={() => handleDeleteEdit(row?.id)}
                                >
                                  <EditIcon width={15} fill="#2b2d42" />
                                </span>
                              </div>
                            </TableCell>
                          );
                        } else if (column.id == "id") {
                          return (
                            <TableCell
                              onClick={() => handleNavigate(row?.id)}
                              key={column.id}
                              align={column.align}
                            >
                              #{value.slice(0, 5)}
                            </TableCell>
                          );
                        } else if (column.id == "photos") {
                          return (
                            <TableCell
                              onClick={() => handleNavigate(row?.id)}
                              key={column.id}
                              align={column.align}
                            >
                              <img
                                style={{ width: "70px" }}
                                src={column.format(value)}
                                alt=""
                              />
                            </TableCell>
                          );
                        }
                        return (
                          <TableCell
                            onClick={() => handleNavigate(row?.id)}
                            key={column.id}
                            align={column.align}
                          >
                            {column.format && typeof value === "number"
                              ? column.format(value)
                              : column.format && column.id == "createdAt"
                              ? column.format(value)
                              : value}
                          </TableCell>
                        );
                      })}
                    </TableRow>
                  );
                })}
            </TableBody>
          </Table>
        </TableContainer>
        <TablePagination
          rowsPerPageOptions={[10, 25, 100]}
          component="div"
          count={myList?.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Paper>
    </div>
  );
};

export default AdsList;
