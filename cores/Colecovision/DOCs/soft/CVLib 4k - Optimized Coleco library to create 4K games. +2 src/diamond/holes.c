/* holes type #1 */
char holes1_dx[]={-1,0,1,-2,-1,0,1,2,-2,-1,0,1,0};
char holes1_dy[]={-2,-2,-2,-1,-1,-1,-1,-1,0,0,0,0,1};

/* holes type #2 */
char holes2_dx[]={-2,-1,0,-2,-1,0,1,-2,-1,0,1,0,1};
char holes2_dy[]={-2,-2,-2,-1,-1,-1,-1,0,0,0,0,1,1};

/* holes type table */
char *holes_dx[]={holes1_dx,holes2_dx};
char *holes_dy[]={holes1_dy,holes2_dy};

/* holes size */
char holes_size = 13;