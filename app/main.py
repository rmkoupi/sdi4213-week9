import streamlit as st
from db import get_engine, initialize_database, create_request, list_requests, update_status

st.set_page_config(page_title="Service Request Tracker", page_icon="🛠️", layout="wide")
st.title("🛠️ Service Request Tracker")
st.caption("SDI 4213 Week 7 – Multi-service application with Docker Compose")

engine = get_engine()
initialize_database(engine)

with st.sidebar:
    st.header("Create Request")
    title = st.text_input("Title")
    category = st.selectbox("Category", ["Hardware", "Software", "Network", "Access", "Other"])
    priority = st.selectbox("Priority", ["Low", "Medium", "High", "Critical"], index=1)
    description = st.text_area("Description")
    if st.button("Submit Request", type="primary"):
        if title.strip() and description.strip():
            create_request(engine, title.strip(), category, priority, description.strip())
            st.success("Request created")
            st.rerun()
        else:
            st.warning("Title and description are required.")

requests = list_requests(engine)

open_count = sum(1 for r in requests if r["status"] == "Open")
progress_count = sum(1 for r in requests if r["status"] == "In Progress")
closed_count = sum(1 for r in requests if r["status"] == "Closed")

c1, c2, c3 = st.columns(3)
c1.metric("Open", open_count)
c2.metric("In Progress", progress_count)
c3.metric("Closed", closed_count)

st.subheader("Current Requests")
if not requests:
    st.info("No requests yet. Create one using the form on the left.")
else:
    st.dataframe(requests, use_container_width=True, hide_index=True)
    ids = [r["id"] for r in requests]
    selected = st.selectbox("Select request to update", ids)
    new_status = st.selectbox("New status", ["Open", "In Progress", "Closed"])
    if st.button("Update Status"):
        update_status(engine, int(selected), new_status)
        st.success("Status updated")
        st.rerun()

st.divider()
st.caption("Tip: In Docker Compose, this app should connect to the database service name `db`, not `localhost`.")
