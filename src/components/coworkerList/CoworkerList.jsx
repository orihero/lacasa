import Paper from "@mui/material/Paper";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableContainer from "@mui/material/TableContainer";
import TableHead from "@mui/material/TableHead";
import TablePagination from "@mui/material/TablePagination";
import TableRow from "@mui/material/TableRow";
import React, { useEffect } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import { formatCreatedAt } from "../../hooks/formatDate";
import { useListStore } from "../../lib/adsListStore";
import "./coworkerList.scss";
import { useCoworkerStore } from "../../lib/useCoworkerStore";

const columns = [
  { id: "id", label: "Id", minWidth: 50 },
  {
    id: "photo",
    label: "Photo",
    minWidth: 100,
    format: (value) => formatCreatedAt(value),
  },
  {
    id: "fullName",
    label: "Ism Familiyasi",
    minWidth: 170,
    align: "left",
    format: (value) => value,
  },
  {
    id: "adsCount",
    label: "Ads Count",
    minWidth: 80,
    align: "left",
    format: (value) => value.toLocaleString("en-US"),
  },
  {
    id: "phoneNumber",
    label: "Phone",
    minWidth: 120,
    align: "left",
    format: (value) => value.toFixed(2),
  },
];

const AdsList = () => {
  const { myList } = useListStore();
  const navigate = useNavigate();
  const { id } = useParams();
  const { t } = useTranslation();
  const { fetchCoworkerList, list } = useCoworkerStore();
  const [page, setPage] = React.useState(0);
  const [rowsPerPage, setRowsPerPage] = React.useState(10);

  useEffect(() => {
    if (id) {
      fetchCoworkerList(id);
    }
  }, [id]);

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(+event.target.value);
    setPage(0);
  };

  const handleDeleteEdit = () => {
    alert("Delete");
  };

  const handleNavigate = (id) => {
    navigate("/post/" + id);
  };

  const handleNavigateNew = () => {
    navigate("/profile/" + id + "/create/coworkers");
  };

  return (
    <div className="ads-list-content">
      {/* <div className="filter-tools">filter</div> */}
      <div className="ads-new">
        <button onClick={handleNavigateNew}>{t("addNewCoworker")}</button>
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
              {[...list]
                ?.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                .map((row) => {
                  return (
                    <TableRow
                      hover
                      role="checkbox"
                      tabIndex={-1}
                      key={row.code}
                      onClick={() => handleNavigate(row?.id)}
                    >
                      {columns.map((column) => {
                        const value = row[column.id];
                        if (column.id == "id") {
                          return (
                            <TableCell key={column.id} align={column.align}>
                              #{value.slice(0, 5)}
                            </TableCell>
                          );
                        }
                        return (
                          <TableCell key={column.id} align={column.align}>
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
