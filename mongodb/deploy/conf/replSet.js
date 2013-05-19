rsconf = {
    _id: "ycsb",
    members: [
        {
            _id: 0,
            host: "#MASTER_MONGODB#:27017"
        }
    ]
}
if (rs.config()==null) {
    rs.initiate( rsconf )
} else {
    rs.reconfig( rsconf )
}
