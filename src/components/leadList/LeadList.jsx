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
import { Drawer } from "@mui/material";
import LeadUpdate from "../leadUpdate/LeadUpdate";
// import { UncontrolledBoard } from "@caldwell619/react-kanban";
// import { board } from "./kanban/data";
// import {
//   Filters,
//   renderCard,
//   Header,
//   renderColumnHeader,
// } from "./kanban/components";
// import {
//   KanbanComponent,
//   ColumnsDirective,
//   ColumnDirective,
// } from "@syncfusion/ej2-react-kanban";

const columns = [
  { id: "id", label: "Id", minWidth: 50 },
  {
    id: "fullName",
    label: "Ism Familiya",
    minWidth: 170,
    format: (value) => formatCreatedAt(value),
  },
  {
    id: "phone",
    label: "Phone",
    minWidth: 120,
    align: "left",
    format: (value) => value,
  },
  {
    id: "comment",
    label: "Commit",
    minWidth: 200,
    align: "center",
    format: (value) => value.toLocaleString("en-US"),
  },
  {
    id: "status",
    label: "Status",
    minWidth: 100,
    align: "left",
    format: (value) => value.toFixed(2),
  },
  {
    id: "source",
    label: "Source",
    minWidth: 100,
    align: "right",
  },
];

let data = [
  {
    Id: 1,
    Status: "Open",
    Summary: "Analyze the new requirements gathered from the customer.",
    Type: "Story",
    Priority: "Low",
    Tags: "Analyze,Customer",
    Estimate: 3.5,
    Assignee: "Nancy Davloio",
    RankId: 1,
  },
  {
    Id: 2,
    Status: "InProgress",
    Summary: "Fix the issues reported in the IE browser.",
    Type: "Bug",
    Priority: "Release Breaker",
    Tags: "IE",
    Estimate: 2.5,
    Assignee: "Janet Leverling",
    RankId: 2,
  },
  {
    Id: 3,
    Status: "Testing",
    Summary: "Fix the issues reported by the customer.",
    Type: "Bug",
    Priority: "Low",
    Tags: "Customer",
    Estimate: "3.5",
    Assignee: "Steven walker",
    RankId: 1,
  },
  {
    Id: 4,
    Status: "Close",
    Summary:
      "Arrange a web meeting with the customer to get the login page requirements.",
    Type: "Others",
    Priority: "Low",
    Tags: "Meeting",
    Estimate: 2,
    Assignee: "Michael Suyama",
    RankId: 1,
  },
  {
    Id: 5,
    Status: "Validate",
    Summary: "Validate new requirements",
    Type: "Improvement",
    Priority: "Low",
    Tags: "Validation",
    Estimate: 1.5,
    Assignee: "Robert King",
    RankId: 1,
  },
];

const AdsList = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const { t } = useTranslation();
  const [page, setPage] = React.useState(0);
  const [rowsPerPage, setRowsPerPage] = React.useState(10);
  const { fetchLeadList, list, fetchLeadListByCwrk } = useLeadStore();
  const { currentUser } = useUserStore();
  const [isOpenDrawer, setIsOpenDrawer] = useState(false);
  const [leadId, setLeadId] = useState(0);

  useEffect(() => {
    if (currentUser.role == "coworker") {
      fetchLeadListByCwrk(currentUser.id);
    } else if (id && currentUser.role == "agent") {
      fetchLeadList(id);
    }
  }, [id]);

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
      {/* <div className="filter-tools">filter</div> */}
      <div className="ads-new">
        <button onClick={handleNavigateNew}>{t("addNewLead")}</button>
      </div>
      {/* <div
        style={{
          width: "1050px",
          maxHeight: "650px",
          overflow: "scroll",
          backgroundColor: "dodgerblue",
        }}
      >
        <KanbanComponent
          id="kanban"
          keyField="Status"
          dataSource={data}
          cardSettings={{ contentField: "Summary", headerField: "Id" }}
        >
          <ColumnsDirective>
            <ColumnDirective headerText="To Do" keyField="Open" />
            <ColumnDirective headerText="In Progress" keyField="InProgress" />
            <ColumnDirective headerText="Testing" keyField="Testing" />
            <ColumnDirective headerText="Done" keyField="Close" />
          </ColumnsDirective>
        </KanbanComponent>

        <UncontrolledBoard
          initialBoard={board}
          renderCard={renderCard}
          renderColumnHeader={renderColumnHeader}
          allowAddCard={true}
          allowAddColumn={true}
          onColumnNew={(column) => console.log("New column", column)}
        />
      </div> */}
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
