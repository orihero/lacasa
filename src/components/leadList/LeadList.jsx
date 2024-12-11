import Paper from "@mui/material/Paper";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableContainer from "@mui/material/TableContainer";
import TableHead from "@mui/material/TableHead";
import TablePagination from "@mui/material/TablePagination";
import TableRow from "@mui/material/TableRow";
import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import { formatCreatedAt } from "../../hooks/formatDate";
import "./leadList.scss";
import { useLeadStore } from "../../lib/useLeadStore";
import StatusCell from "../status/StatusCell";
import { useUserStore } from "../../lib/userStore";
import { Drawer, styled, Typography } from "@mui/material";
import LeadUpdate from "../leadUpdate/LeadUpdate";

const AdsList = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const { t } = useTranslation();
  const [page, setPage] = React.useState(0);
  const [rowsPerPage, setRowsPerPage] = React.useState(10);
  const { fetchLeadList, list } = useLeadStore();
  const { currentUser } = useUserStore();
  const [isOpenDrawer, setIsOpenDrawer] = useState(false);
  const [leadId, setLeadId] = useState(0);

  const columns = [
    { id: "id", label: t("id"), minWidth: 50 },
    {
      id: "fullName",
      label: t("fullName"),
      minWidth: 170,
      format: (value) => formatCreatedAt(value),
    },
    {
      id: "phone",
      label: t("phone"),
      minWidth: 120,
      align: "left",
      format: (value) => value,
    },
    {
      id: "comment",
      label: t("commit"),
      minWidth: 200,
      align: "center",
      format: (value) => value.toLocaleString("en-US"),
    },
    {
      id: "status",
      label: t("status"),
      minWidth: 100,
      align: "left",
      format: (value) => value.toFixed(2),
    },
    {
      id: "source",
      label: t("source"),
      minWidth: 100,
      align: "right",
    },
  ];

  // useEffect(() => {
  //   if (currentUser.role == "coworker") {
  //     fetchLeadListByCwrk(currentUser.id);
  //   } else if (id && currentUser.role == "agent") {
  //     fetchLeadList(id);
  //   }
  // }, [id]);
  useEffect(() => {
    if (currentUser.role == "coworker") {
      fetchLeadList(currentUser?.agentId);
    } else if (currentUser.role == "agent") {
      fetchLeadList(id);
    }
  }, [currentUser?.agentId, id]);

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(+event.target.value);
    setPage(0);
  };

  const handleNavigate = (id) => {
    navigate("/profile/" + id + "/update/leads");
  };

  const handleNavigateNew = () => {
    navigate("/profile/" + id + "/create/leads");
  };

  return (
    <div className="ads-list-content">
      <div className="ads-new">
        <button onClick={handleNavigateNew}>{t("addNewLead")}</button>
      </div>
      <Paper sx={{ width: "100%", overflow: "hidden" }}>
        <TableContainer sx={{ maxHeight: 540 }}>
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
                      onClick={() => {
                        setIsOpenDrawer(true);
                        setLeadId(row?.id);
                      }}
                    >
                      {columns.map((column) => {
                        const value = row[column.id];
                        if (column.id == "id") {
                          return (
                            <TableCell key={column.id} align={column.align}>
                              #{value.slice(0, 5)}
                            </TableCell>
                          );
                        } else if (column.id == "status") {
                          return (
                            <TableCell key={column.id} align={column.align}>
                              <StatusCell value={value} />
                            </TableCell>
                          );
                        }
                        return (
                          <TableCell key={column.id} align={column.align}>
                            {column.format && typeof value === "number"
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
          count={list?.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Paper>
      <Drawer
        anchor={"right"}
        open={isOpenDrawer}
        onClose={() => setIsOpenDrawer(false)}
      >
        <LeadUpdate leadId={leadId} onClose={() => setIsOpenDrawer(false)} />
      </Drawer>
    </div>
  );
};

export default AdsList;
