const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const moment = require('moment');

const app = express();
app.use(express.json());
app.use(cors());

// PostgreSQL connection pool
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'postgres',
  password: '5128512',
  port: 5432,
});

// Login endpoint
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const { rows } = await pool.query(
      'SELECT * FROM player WHERE player_email = $1 AND player_password = $2',
      [email, password]
    );

    if (rows.length > 0) {
      res.status(200).json({ message: 'Login successful' });
    } else {
      res.status(401).json({ message: 'Invalid credentials' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// User Retrieval endpoint
app.get('/user', async (req, res) => {
	const { email } = req.query;
	
  try {
    const result = await pool.query(
      'SELECT player_username FROM player WHERE player_email = $1',
      [email]
    );
    if (result.rows.length > 0) {
      const username = result.rows[0].player_username; // Accessing the username from query results
      res.json({ username });
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    // Handle any errors that occur during the database query
    console.error('Error retrieving user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Registration endpoint
app.post('/register', async (req, res) => {
  const { username, email, password, gender } = req.body;

  try {
    // Check if the email already exists
    const existingUser = await pool.query('SELECT * FROM player WHERE player_email = $1', [email]);

    if (existingUser.rows.length > 0) {
      return res.status(409).json({ message: 'Email already exists' });
    }

    // Insert the new user into the database
    const newUser = await pool.query(
      'INSERT INTO player (player_username, player_password, player_email, player_gender) VALUES ($1, $2, $3, $4) RETURNING *',
      [username, password, email, gender]
    );

    res.status(201).json({ message: 'Registration successful', user: newUser.rows[0] });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Admin Login endpoint
app.post('/adminlogin', async (req, res) => {
  const { username, password } = req.body;

  try {
    const { rows } = await pool.query(
      'SELECT * FROM admin WHERE admin_username = $1 AND admin_password = $2',
      [username, password]
    );

    if (rows.length > 0) {
      res.status(200).json({ message: 'Login successful' });
    } else {
      res.status(401).json({ message: 'Invalid credentials' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Script Retrieval endpoint
app.get('/scripts', async (req, res) => {
  try {
    const query = `
      SELECT 
        script_id, 
        script_name, 
        script_playercount, 
        script_time,
		script_playermax,
		script_malemax,
		script_femalemax,
        script_genre,
        script_type,
        script_contentwarning,
		script_featured
      FROM script
    `;

    const { rows } = await pool.query(query);

    const scripts = rows.map(row => ({
      id: row.script_id,
      name: row.script_name,
      playercount: row.script_playercount,
      time: row.script_time,
	  playermax: row.script_playermax,
	  malemax: row.script_malemax,
	  femalemax: row.script_femalemax,
      genre: row.script_genre,
      type: row.script_type,
      contentwarnings: row.script_contentwarning,
	  featured: row.script_featured
    }));

    res.json(scripts);
  } catch (error) {
    console.error('Error retrieving scripts:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Public Booking Retrieval endpoint
app.get('/publicbooking', async (req, res) => {
  try {
    const { username } = req.query;

    const playerQuery = `
      SELECT player_id
      FROM player
      WHERE player_username = $1
    `;
    const playerResult = await pool.query(playerQuery, [username]);
    const playerId = playerResult.rows[0]?.player_id;

    if (!playerId) {
      return res.status(404).json({ error: 'Player not found' });
    }

    const participationQuery = `
      SELECT booking_id
      FROM participation
      WHERE player_id = $1
    `;
    const participationResult = await pool.query(participationQuery, [playerId]);
    const joinedBookingIds = participationResult.rows.map(row => row.booking_id);
    const query = `
      SELECT
        booking.booking_id,
        script.script_name,
        script.script_playermax,
        script.script_malemax,
        script.script_femalemax,
        player.player_username,
        booking.booking_date,
        booking.booking_start,
        booking.booking_end,
        booking.booking_state,
        booking.player_id,
        booking.booking_experience,
        booking.booking_gender,
        booking.booking_playercount,
        booking.booking_malecount,
        booking.booking_femalecount
      FROM booking
      INNER JOIN script ON booking.script_id = script.script_id
      INNER JOIN player ON booking.player_id = player.player_id
      WHERE booking.booking_state = 'public'
        AND booking.booking_status = 'searching'
        AND booking.booking_id NOT IN (SELECT unnest($1::int[]))
    `;

    const { rows } = await pool.query(query, [joinedBookingIds]);

    const publicBookings = rows.map(row => ({
      booking_id: row.booking_id,
      script_name: row.script_name,
      player_name: row.player_username,
      date: row.booking_date,
      start: row.booking_start,
      end: row.booking_end,
      experience: row.booking_experience,
      gender: row.booking_gender,
      playercount: row.booking_playercount,
      malecount: row.booking_malecount,
      femalecount: row.booking_femalecount,
      playermax: row.script_playermax,
      malemax: row.script_malemax,
      femalemax: row.script_femalemax
    }));

    res.json(publicBookings);
  } catch (error) {
    console.error('Error retrieving public bookings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Booking Timecheck endpoint
app.get('/checktimes', async (req, res) => {
  const { date: dateString, scriptId, username} = req.query;

  try {
	const playerIDcheck = await pool.query('SELECT * FROM player WHERE player_username = $1', [username]);
    const playerID = playerIDcheck.rows[0].player_id;

     const participationIds = await pool.query('SELECT booking_id FROM participation WHERE player_id = $1', [playerID]);
    const bookingIdArray = participationIds.rows.map(row => row.booking_id);
	
	const date = new Date(dateString);
    const bookingsSetA = (await pool.query(
      `SELECT * FROM booking WHERE booking_id = ANY($1) AND booking_date = $2`,
      [bookingIdArray, date]
    )).rows;

    // Fetch bookings from script ID and date (set B)
    const bookingsSetB = await pool.query('SELECT * FROM booking WHERE script_id = $1 AND booking_date = $2', [scriptId, date]);

    // Merge bookings set A and set B
    const allBookingIds = [...new Set([...bookingsSetA.map(row => row.booking_id), ...bookingsSetB.rows.map(row => row.booking_id)])];
    const bookingQuery = `
      SELECT * FROM booking
      WHERE booking_id = ANY($1)
    `;
    const bookingValues = [allBookingIds];
    const bookingResult = await pool.query(bookingQuery, bookingValues);
	
    console.log('Merged bookings:', bookingResult.rows);

    console.log('Input values:', scriptId, date);

    const startTimeQuery = 'SELECT booking_start FROM booking WHERE booking_id = ANY($1)';
    const startTimeResult = await pool.query(startTimeQuery, [allBookingIds]);
    console.log('startTimeResult:', startTimeResult.rows);

    const scriptTimeQuery = 'SELECT script_time FROM script WHERE script_id = $1';
    const scriptTimeResult = await pool.query(scriptTimeQuery, [scriptId]);
    console.log('scriptTimeResult:', scriptTimeResult.rows);
    const scriptTime = scriptTimeResult.rows[0].script_time;
    console.log('scriptTimeResult:', scriptTime);

    const endTimeQuery = 'SELECT booking_end FROM booking WHERE booking_id = ANY($1)';
    const endTimeResult = await pool.query(endTimeQuery, [allBookingIds]);
    console.log('endTimeResult:', endTimeResult.rows);
	
    const scriptTimeLength = scriptTimeResult.rows[0].script_time;
    const scriptHours = scriptTimeLength.hours;
    const scriptMinutes = scriptTimeLength.minutes ?? 0; 
    const scriptMilliseconds = scriptHours * 60 * 60 * 1000 + scriptMinutes * 60 * 1000;
    console.log('milliseconds:', scriptMilliseconds);

    const timeRanges = [];
    let startTime, endTime;

    for (let i = 0; i < startTimeResult.rows.length; i++) {
        const startTimeString = startTimeResult.rows[i].booking_start;
        const endTimeString = endTimeResult.rows[i].booking_end;

        startTime = new Date(`${dateString}T${startTimeString}`);
        endTime = new Date(`${dateString}T${endTimeString}`);
	
        startTime.setHours(startTime.getHours() + 8); // Adjust timezone offset here if necessary
        endTime.setHours(endTime.getHours() + 8); // Adjust timezone offset here if necessary
	
        console.log('Timecheck:', startTime, endTime);

        const newStartTime = new Date(startTime.getTime() - scriptMilliseconds);

        timeRanges.push({ startTime: newStartTime, endTime: endTime });
    }

    endTime = new Date(dateString);
    endTime.setUTCHours(23, 59, 59, 0);
    startTime = new Date(endTime.getTime() - scriptMilliseconds);
    timeRanges.push({ startTime: startTime, endTime: endTime });
    console.log('Timecheck:', startTime, endTime);

    res.status(200).json(timeRanges);
 
  } catch (error) {
    console.error('Error executing query', error.stack);
    res.status(500).json({ error: 'Error executing query' });
  }
});

// Booking Timecheck endpoint
app.get('/checkrooms', async (req, res) => {
  const { date: dateString} = req.query;

  try {
	const date = new Date(dateString);
    const bookings = (await pool.query(
      `SELECT * FROM booking WHERE booking_date = $1`,
      [date]
    )).rows;

    const allBookingIds = [...new Set([...bookings.map(row => row.booking_id)])];
    const bookingQuery = `
      SELECT * FROM booking
      WHERE booking_id IN (${allBookingIds.map((_, i) => `$${i + 1}`).join(',')})
    `;
    const bookingValues = allBookingIds;
    const bookingResult = await pool.query(bookingQuery, bookingValues);

    console.log('All bookings:', bookings.rows); 

    console.log('Input values:', date);

    const startTimeQuery = 'SELECT booking_start FROM booking WHERE booking_id = ANY($1)';
    const startTimeResult = await pool.query(startTimeQuery, [allBookingIds]);
    console.log('startTimeResult:', startTimeResult.rows);

    const endTimeQuery = 'SELECT booking_end FROM booking WHERE booking_id = ANY($1)';
    const endTimeResult = await pool.query(endTimeQuery, [allBookingIds]);
    console.log('endTimeResult:', endTimeResult.rows);

    const timeRanges = [];
    let startTime, endTime;

    for (let i = 0; i < startTimeResult.rows.length; i++) {
        const startTimeString = startTimeResult.rows[i].booking_start;
        const endTimeString = endTimeResult.rows[i].booking_end;

        startTime = new Date(`${dateString}T${startTimeString}`);
        endTime = new Date(`${dateString}T${endTimeString}`);
	
        startTime.setHours(startTime.getHours() + 8); // Adjust timezone offset here if necessary
        endTime.setHours(endTime.getHours() + 8); // Adjust timezone offset here if necessary
	
        console.log('Timecheck:', startTime, endTime);

        timeRanges.push({ startTime: startTime, endTime: endTime });
    }

    res.status(200).json(timeRanges);
 
  } catch (error) {
    console.error('Error executing query', error.stack);
    res.status(500).json({ error: 'Error executing query' });
  }
});

// Booking endpoint
app.post('/book', async (req, res) => {
  const { username, scriptId, time: ampmtime, date: dateString, state, experience, gender } = req.body;

  try {
	// Fetch PlayerID.
	console.log('usernamecheck:', username);
	const playerIDcheck = await pool.query('SELECT * FROM player WHERE player_username = $1', [username]);
	console.log('playerIDcheck:', playerIDcheck);
	const playerID = playerIDcheck.rows[0].player_id;
	
	// Fetch Player gender.
	const playerGender = playerIDcheck.rows[0].player_gender;
	
	let bookingstate
	if (state === true) {
     bookingstate = "private";
} else {
     bookingstate = "public";
}
	
	// Fetch available rooms.
	const availableRoomsQuery = 'SELECT room_id FROM rooms WHERE room_status = $1';
    const availableRoomsValues = ['available'];
	const availableRoomsResult = await pool.query(availableRoomsQuery, availableRoomsValues);
    const availableRoomIds = availableRoomsResult.rows.map(row => row.room_id);
	
    // Check if the booking overlaps.
    const date = new Date(dateString);
	const time = new moment(ampmtime, ['h:mm A']).format('HH:mm:ss');
    console.log('Input values:', scriptId, date, time);

    const startTimeQuery = 'SELECT booking_start FROM booking WHERE script_id = $1 AND booking_date = $2';
    const startTimeResult = await pool.query(startTimeQuery, [scriptId, date]);
    console.log('startTimeResult:', startTimeResult.rows);

    const scriptTimeQuery = 'SELECT script_time FROM script WHERE script_id = $1';
    const scriptTimeResult = await pool.query(scriptTimeQuery, [scriptId]);
    console.log('scriptTimeResult:', scriptTimeResult.rows);
    const scriptTime = scriptTimeResult.rows[0].script_time;
    console.log('scriptTimeResult:', scriptTime);

    const endTimeQuery = 'SELECT booking_end FROM booking WHERE script_id = $1 AND booking_date = $2';
    const endTimeResult = await pool.query(endTimeQuery, [scriptId, date]);
    console.log('endTimeResult:', endTimeResult.rows);
	
    const scriptTimeLength = scriptTimeResult.rows[0].script_time;
    const scriptHours = scriptTimeLength.hours;
    const scriptMinutes = scriptTimeLength.minutes ?? 0; 
    const scriptMilliseconds = scriptHours * 60 * 60 * 1000 + scriptMinutes * 60 * 1000;
    console.log('milliseconds:', scriptMilliseconds);

    const timeRanges = [];
    let startTime, endTime;

    for (let i = 0; i < startTimeResult.rows.length; i++) {
        const startTimeString = startTimeResult.rows[i].booking_start;
        const endTimeString = endTimeResult.rows[i].booking_end;

        startTime = new Date(`${dateString}T${startTimeString}`);
        endTime = new Date(`${dateString}T${endTimeString}`);
	
        startTime.setHours(startTime.getHours() + 8); // Adjust timezone offset here if necessary
        endTime.setHours(endTime.getHours() + 8); // Adjust timezone offset here if necessary

        const newStartTime = new Date(startTime.getTime() - scriptMilliseconds);
		console.log('Timecheck:', newStartTime, endTime);
        timeRanges.push({ startTime: newStartTime, endTime: endTime });
    }
	
	let isOverlapping = false;
	timecheck = new Date(`${dateString}T${time}`);
	timecheck.setHours(timecheck.getHours() + 8);
	console.log('Timecheck:', timecheck);

    for (let i = 0; i < timeRanges.length; i++) {
    const startTime = timeRanges[i].startTime;
    const endTime = timeRanges[i].endTime;

    if (endTime && timecheck >= startTime && timecheck < endTime) 
	{
        isOverlapping = true;
        break;
    }
}
	
	console.log('overlapCheck:', isOverlapping);
	
	if (isOverlapping) {
     return res.status(409).json({ message: 'Booking time overlaps with an existing booking' });
    }
	
	//Get booking_end
	
	startTime = new Date(`${dateString}T${time}`);
	endTime = new Date(startTime.getTime() + scriptMilliseconds);
	
    const startTimeString = startTime.toLocaleTimeString('en-US', { hour12: false });
    const endTimeString = endTime.toLocaleTimeString('en-US', { hour12: false });
	let bookingstatus;
	
	//Set booking status
	if (state === 'public') {
  bookingstatus = 'searching';
} else {
  bookingstatus = 'pending';
}

    let assignedRoomId = null;
	console.log('available rooms:', availableRoomIds);
 for (const roomId of availableRoomIds) { // Check for time overlap with the current room
   const startTimeQuery = 'SELECT booking_start FROM booking WHERE room_id = $1 AND booking_date = $2';
        const startTimeResult = await pool.query(startTimeQuery, [roomId, date]);
        console.log('startTimeResult:', startTimeResult.rows);

        const endTimeQuery = 'SELECT booking_end FROM booking WHERE room_id = $1 AND booking_date = $2';
        const endTimeResult = await pool.query(endTimeQuery, [roomId, date]);
        console.log('endTimeResult:', endTimeResult.rows);
		
		const scriptTimeQuery = 'SELECT script_time FROM script WHERE script_id = $1';
    const scriptTimeResult = await pool.query(scriptTimeQuery, [scriptId]);
    console.log('scriptTimeResult:', scriptTimeResult.rows);
    const scriptTime = scriptTimeResult.rows[0].script_time;
    console.log('scriptTimeResult:', scriptTime);
	
	    const scriptTimeLength = scriptTimeResult.rows[0].script_time;
    const scriptHours = scriptTimeLength.hours;
    const scriptMinutes = scriptTimeLength.minutes ?? 0; 
    const scriptMilliseconds = scriptHours * 60 * 60 * 1000 + scriptMinutes * 60 * 1000;
    console.log('milliseconds:', scriptMilliseconds);
		
		let startTime, endTime;
		
		startTime = new Date(`${dateString}T${time}`);
	    endTime = new Date(startTime.getTime() + scriptMilliseconds);
		
		startTime.setHours(startTime.getHours() + 8); // Adjust timezone offset here if necessary
        endTime.setHours(endTime.getHours() + 8); 
		
		console.log('startTime:', startTime);
		console.log('endTime:', endTime);

        const timeRanges = [];

        for (let i = 0; i < startTimeResult.rows.length; i++) {
            const startTimeString = startTimeResult.rows[i].booking_start;
            const endTimeString = endTimeResult.rows[i].booking_end;
			
			console.log('Timecheck:', startTimeString, endTimeString);

            startTime = new Date(`${dateString}T${startTimeString}`);
            endTime = new Date(`${dateString}T${endTimeString}`);

            startTime.setHours(startTime.getHours() + 8); // Adjust timezone offset here if necessary
            endTime.setHours(endTime.getHours() + 8); // Adjust timezone offset here if necessary

            const newStartTime = new Date(startTime.getTime() - scriptMilliseconds);
            console.log('Timecheck:', newStartTime, endTime);
            timeRanges.push({ startTime: newStartTime, endTime: endTime });
        }

        let isOverlapping = false;
        const timecheck = startTime
        console.log('Timecheck:', timecheck);

        for (let i = 0; i < timeRanges.length; i++) {
            const startTime = timeRanges[i].startTime;
            const endTime = timeRanges[i].endTime;

            if (endTime && timecheck >= startTime && timecheck < endTime) {
                isOverlapping = true;
                break;
            }
        }

        if (!isOverlapping) {
            assignedRoomId = roomId;
			console.log('roomId:', roomId);
            break;
        }
	}
	
	console.log('InsertionCheck', playerID, scriptId, startTimeString, endTimeString, date, bookingstate, experience, gender, bookingstatus, assignedRoomId);

	let insertQuery;
    let insertValues;

    insertQuery = `
  INSERT INTO booking
  (player_id, script_id, booking_start, booking_end, booking_date, booking_state, booking_experience, booking_gender, booking_malecount, booking_femalecount, booking_status, room_id)
  VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
  RETURNING booking_id
`;

if (playerGender === 'Male') {
  insertValues = [playerID, scriptId, startTimeString, endTimeString, date, bookingstate, experience, gender, 1, 0, bookingstatus, assignedRoomId];
} else {
  insertValues = [playerID, scriptId, startTimeString, endTimeString, date, bookingstate, experience, gender, 0, 1, bookingstatus, assignedRoomId];
}

	const result = await pool.query(insertQuery, insertValues);
    const bookingID = result.rows[0].booking_id;
	
	const insertParticipation = 'INSERT INTO participation (player_id, booking_id) VALUES ($1, $2)';
	const participationValues  = [playerID, bookingID];
	await pool.query(insertParticipation, participationValues);

    res.status(201).json({ message: 'Booking successful'});
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Join public booking endpoint
app.post('/join', async (req, res) => {
  const { username, bookingID } = req.query;

  try {
    // Fetch player ID and gender
    const playerIDcheck = await pool.query('SELECT * FROM player WHERE player_username = $1', [username]);
    const playerID = playerIDcheck.rows[0].player_id;
    const playerGender = playerIDcheck.rows[0].player_gender;
	const playerExperience = playerIDcheck.rows[0].player_playedcases;

    const insertParticipation = 'INSERT INTO participation (player_id, booking_id) VALUES ($1, $2)';
    const participationValues  = [playerID, bookingID];
	
	const bookingResult = await pool.query('SELECT * FROM booking WHERE booking_id = $1', [bookingID]);
    const scriptId = bookingResult.rows[0].script_id;
	const bookingGenderPref = bookingResult.rows[0].booking_gender;
	const bookingExperience = bookingResult.rows[0].booking_experience;

    let updateQuery;
    let updateValues;
	
	// Check booking validity
	
	// Booking overlap check
	
	const timeRanges = [];
	let otherbookingids = [];
    let startTime, endTime;
	
	otherbookingids = await pool.query('SELECT booking_id FROM participation WHERE player_id = $1', [playerID]);
    const bookingIdArray = otherbookingids.rows;
    console.log('Booking IDs:', bookingIdArray);

    if (bookingIdArray.length > 0) {
     for (let i = 0; i < bookingIdArray.length; i++) {
      const bookingid = bookingIdArray[i].booking_id;
	  console.log('Booking ID:', bookingid);
      const bookingQuery = await pool.query('SELECT * FROM booking WHERE booking_id = $1', [bookingid]);
      const startTime = bookingQuery.rows[0].booking_start;
      const endTime = bookingQuery.rows[0].booking_end;
      console.log('Booking check:', startTime, endTime);
      timeRanges.push({ startTime, endTime });
    }
  }

    let isOverlapping = false;
    const start_timecheck = bookingResult.rows[0].booking_start;
    const end_timecheck = bookingResult.rows[0].booking_end;

    for (let i = 0; i < timeRanges.length; i++) {
     const startTime = timeRanges[i].startTime;
     const endTime = timeRanges[i].endTime;
	 
	console.log('start, startcheck, end, endcheck:', start_timecheck, startTime, end_timecheck, endTime);

    if (
    (start_timecheck >= startTime && start_timecheck < endTime) ||
    (end_timecheck > startTime && end_timecheck <= endTime) ||
    (start_timecheck <= startTime && end_timecheck >= endTime)
  ) {
    isOverlapping = true;
    break;
  }
}

    console.log('overlapCheck:', isOverlapping);

    if (isOverlapping) {
     return res.status(409).json({ message: 'Booking time overlaps with an existing booking' });
    }
	
	// Capacity check
	
	currentPlayersResult = await pool.query('SELECT booking_playercount FROM booking WHERE booking_id = $1', [bookingID]);
    currentPlayers = currentPlayersResult.rows[0].booking_playercount;
 
    maxPlayersResult = await pool.query('SELECT script_playermax FROM script WHERE script_id = $1', [scriptId]);
    maxPlayers = maxPlayersResult.rows[0].script_playermax;

    console.log('Player Amount:', currentPlayers, 'Player Max:', maxPlayers);

    if (currentPlayers === maxPlayers) {
     return res.status(409).json({ message: 'Player maximum exceeded' });
    }
	
	// Gender mismatch check
	
	if (bookingGenderPref == 'YES') {
	if (playerGender === 'Male') {
	  const currentMPlayersResult = await pool.query('SELECT booking_malecount FROM booking WHERE booking_id = $1', [bookingID]);
      const currentMPlayers = currentMPlayersResult.rows[0].booking_malecount;
 
      const maxMPlayersResult = await pool.query('SELECT script_malemax FROM script WHERE script_id = $1', [scriptId]);
      const maxMPlayers = maxMPlayersResult.rows[0].script_malemax;
	  console.log('Male Player Amount:', currentMPlayers, 'Male Player Max:', maxMPlayers);
	  if (currentMPlayers == maxMPlayers) {
      return res.status(409).json({ message: 'Male player maximum exceeded' });
    }
    } else {
      const currentFPlayersResult = await pool.query('SELECT booking_femalecount FROM booking WHERE booking_id = $1', [bookingID]);
      const currentFPlayers = currentFPlayersResult.rows[0].booking_femalecount;
 
      const maxFPlayersResult = await pool.query('SELECT script_femalemax FROM script WHERE script_id = $1', [scriptId]);
      const maxFPlayers = maxFPlayersResult.rows[0].script_femalemax;
	  console.log('Female Player Amount:', currentFPlayers, 'Female Player Max:', maxFPlayers);
	  if (currentFPlayers == maxFPlayers) {
      return res.status(409).json({ message: 'Female player maximum exceeded' });
    }
	}
	}
	
	// Player experience check
	console.log('Player played cases:', playerExperience, 'Cases played requirement:', bookingExperience);
	if (playerExperience < bookingExperience) {
	  return res.status(409).json({ message: 'Player does not meet cases played requirement' });
    }

    if (playerGender === 'Male') {
      updateQuery = `
        UPDATE booking
        SET booking_malecount = booking_malecount + 1,
            booking_playercount = booking_playercount + 1
        WHERE booking_id = $1`;
      updateValues = [bookingID];
    } else {
      updateQuery = `
        UPDATE booking
        SET booking_femalecount = booking_femalecount + 1,
            booking_playercount = booking_playercount + 1
        WHERE booking_id = $1`;
      updateValues = [bookingID];
    }
    await pool.query(updateQuery, updateValues); 
	await pool.query(insertParticipation, participationValues);
	
	// Capacity check + status update
	
	console.log('Player Amount:', currentPlayers, 'Player Max:', maxPlayers);
	
	currentPlayersResult = await pool.query('SELECT booking_playercount FROM booking WHERE booking_id = $1', [bookingID]);
    currentPlayers = currentPlayersResult.rows[0].booking_playercount;
 
    maxPlayersResult = await pool.query('SELECT script_playermax FROM script WHERE script_id = $1', [scriptId]);
    maxPlayers = maxPlayersResult.rows[0].script_playermax;

    console.log('Player Amount:', currentPlayers, 'Player Max:', maxPlayers);

    if (currentPlayers === maxPlayers) {
     updateQuery = `
        UPDATE booking
        SET booking_status = 'pending'
        WHERE booking_id = $1`;
     updateValues = [bookingID];
	 await pool.query(updateQuery, updateValues); 
    }

    res.status(201).json({ message: 'Successfully joined existing booking!' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Player Booking Retrieval endpoint
app.get('/playerbooking', async (req, res) => {
  try {
    const { username } = req.query;

    const playerResult = await pool.query('SELECT player_id FROM player WHERE player_username = $1', [username]);
    const playerId = playerResult.rows[0].player_id;

    const participationQuery = `
      SELECT booking_id
      FROM participation
      WHERE player_id = $1
    `;
    const { rows: participationRows } = await pool.query(participationQuery, [playerId]);
    const bookingIds = participationRows.map(row => row.booking_id);

    if (bookingIds.length === 0) {
      return res.json([]);
    }

    const bookingQuery = `
      SELECT
        booking.booking_id,
        script.script_name,
		script.script_time,
        script.script_playermax,
        script.script_malemax,
        script.script_femalemax,
        player.player_username,
        booking.booking_date,
        booking.booking_start,
        booking.booking_end,
        booking.booking_state,
        booking.player_id,
        booking.booking_experience,
        booking.booking_gender,
        booking.booking_playercount,
        booking.booking_malecount,
        booking.booking_femalecount,
        booking.booking_status,
		booking.booking_reviewed
      FROM booking
      INNER JOIN script ON booking.script_id = script.script_id
      INNER JOIN player ON booking.player_id = player.player_id
      WHERE booking.booking_id = ANY($1)
    `;
    const { rows } = await pool.query(bookingQuery, [bookingIds]);
	
    if (rows.length !== 0) {
      const playerBookings = rows.map(row => {
        const isPlayerOwner = row.player_id === playerId;
        return {
          booking_id: row.booking_id,
          script_name: row.script_name,
          player_name: row.player_username,
          date: row.booking_date,
		  time: row.script_time,
          start: row.booking_start,
          end: row.booking_end,
          experience: row.booking_experience,
          gender: row.booking_gender,
          playercount: row.booking_playercount,
          malecount: row.booking_malecount,
          femalecount: row.booking_femalecount,
          playermax: row.script_playermax,
          malemax: row.script_malemax,
          femalemax: row.script_femalemax,
          bookingstatus: row.booking_status,
          playerowner: isPlayerOwner ? 'yes' : 'no',
		  reviewed: row.booking_reviewed
        };
      });

    res.json(playerBookings);
  }
  }  catch (error) {
    console.error('Error retrieving user bookings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Leave public booking endpoint
app.post('/leave', async (req, res) => {
  const { username, bookingID } = req.query;

  try {
    // Fetch player ID and gender
    const playerIDcheck = await pool.query('SELECT * FROM player WHERE player_username = $1', [username]);
    const playerID = playerIDcheck.rows[0].player_id;
    const playerGender = playerIDcheck.rows[0].player_gender;

    const deleteParticipation = 'DELETE FROM participation WHERE player_id = $1 AND booking_id = $2';
    const participationValues = [playerID, bookingID];
	
	const bookingResult = await pool.query('SELECT * FROM booking WHERE booking_id = $1', [bookingID]);
	const scriptId = bookingResult.rows[0].script_id;

    let updateQuery;
    let updateValues;

    if (playerGender === 'Male') {
  updateQuery = `
    UPDATE booking
    SET booking_malecount = booking_malecount - 1,
        booking_playercount = booking_playercount - 1
    WHERE booking_id = $1;
  `;
  updateValues = [bookingID];
} else {
  updateQuery = `
    UPDATE booking
    SET booking_femalecount = booking_femalecount - 1,
        booking_playercount = booking_playercount - 1
    WHERE booking_id = $1;
  `;
  updateValues = [bookingID];
}

    await pool.query(updateQuery, updateValues); 
	await pool.query(deleteParticipation, participationValues);
	
	// Capacity check + status update
	
	console.log('Player Amount:', currentPlayers, 'Player Max:', maxPlayers);
	
	currentPlayersResult = await pool.query('SELECT booking_playercount FROM booking WHERE booking_id = $1', [bookingID]);
    currentPlayers = currentPlayersResult.rows[0].booking_playercount;
 
    maxPlayersResult = await pool.query('SELECT script_playermax FROM script WHERE script_id = $1', [scriptId]);
    maxPlayers = maxPlayersResult.rows[0].script_playermax;

    console.log('Player Amount:', currentPlayers, 'Player Max:', maxPlayers);

    if (currentPlayers != maxPlayers) {
     updateQuery = `
        UPDATE booking
        SET booking_status = 'searching'
        WHERE booking_id = $1`;
     updateValues = [bookingID];
	 await pool.query(updateQuery, updateValues); 
    }

    res.status(201).json({ message: 'Successfully joined existing booking!' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.get('/checktimesalter', async (req, res) => {
  const { bookingId, date: dateString, username} = req.query;

  try {
	const playerIDcheck = await pool.query('SELECT * FROM player WHERE player_username = $1', [username]);
    const playerID = playerIDcheck.rows[0].player_id;
	
	const scriptIDcheck = await pool.query('SELECT * FROM booking WHERE booking_id = $1', [bookingId]);
    const scriptId = scriptIDcheck.rows[0].script_id;

    const participationIds = await pool.query('SELECT booking_id FROM participation WHERE player_id = $1', [playerID]);
    const bookingIdArray = participationIds.rows.map(row => row.booking_id);
	
	const date = new Date(dateString);
    const bookingsSetA = (await pool.query(
      `SELECT * FROM booking WHERE booking_id = ANY($1) AND booking_date = $2`,
      [bookingIdArray, date]
    )).rows;

    // Fetch bookings from script ID and date (set B)
    const bookingsSetB = await pool.query('SELECT * FROM booking WHERE script_id = $1 AND booking_date = $2', [scriptId, date]);

    // Merge bookings set A and set B
    const allBookingIds = [...new Set([...bookingsSetA.map(row => row.booking_id), ...bookingsSetB.rows.map(row => row.booking_id)])];
	const filteredBookingIds = allBookingIds.filter(id => id !== parseInt(bookingId));
    const bookingQuery = `
      SELECT * FROM booking
      WHERE booking_id IN (${filteredBookingIds.map((_, i) => `$${i + 1}`).join(',')})
    `;
    const bookingValues = filteredBookingIds;
    const bookingResult = await pool.query(bookingQuery, bookingValues);

    console.log('Merged bookings:', bookingResult.rows); 

    console.log('Input values:', scriptId, date);

    const startTimeQuery = 'SELECT booking_start FROM booking WHERE booking_id = ANY($1)';
    const startTimeResult = await pool.query(startTimeQuery, [filteredBookingIds]);
    console.log('startTimeResult:', startTimeResult.rows);

    const scriptTimeQuery = 'SELECT script_time FROM script WHERE script_id = $1';
    const scriptTimeResult = await pool.query(scriptTimeQuery, [scriptId]);
    console.log('scriptTimeResult:', scriptTimeResult.rows);
    const scriptTime = scriptTimeResult.rows[0].script_time;
    console.log('scriptTimeResult:', scriptTime);

    const endTimeQuery = 'SELECT booking_end FROM booking WHERE booking_id = ANY($1)';
    const endTimeResult = await pool.query(endTimeQuery, [filteredBookingIds]);
    console.log('endTimeResult:', endTimeResult.rows);
	
    const scriptTimeLength = scriptTimeResult.rows[0].script_time;
    const scriptHours = scriptTimeLength.hours;
    const scriptMinutes = scriptTimeLength.minutes ?? 0; 
    const scriptMilliseconds = scriptHours * 60 * 60 * 1000 + scriptMinutes * 60 * 1000;
    console.log('milliseconds:', scriptMilliseconds);

    const timeRanges = [];
    let startTime, endTime;

    for (let i = 0; i < startTimeResult.rows.length; i++) {
        const startTimeString = startTimeResult.rows[i].booking_start;
        const endTimeString = endTimeResult.rows[i].booking_end;

        startTime = new Date(`${dateString}T${startTimeString}`);
        endTime = new Date(`${dateString}T${endTimeString}`);
	
        startTime.setHours(startTime.getHours() + 8); // Adjust timezone offset here if necessary
        endTime.setHours(endTime.getHours() + 8); // Adjust timezone offset here if necessary
	
        console.log('Timecheck:', startTime, endTime);

        const newStartTime = new Date(startTime.getTime() - scriptMilliseconds);

        timeRanges.push({ startTime: newStartTime, endTime: endTime });
    }

    endTime = new Date(dateString);
    endTime.setUTCHours(23, 59, 59, 0);
    startTime = new Date(endTime.getTime() - scriptMilliseconds);
    timeRanges.push({ startTime: startTime, endTime: endTime });
    console.log('Timecheck:', startTime, endTime);

    res.status(200).json(timeRanges);
 
  } catch (error) {
    console.error('Error executing query', error.stack);
    res.status(500).json({ error: 'Error executing query' });
  }
});

// Alter Booking endpoint
app.post('/alter', async (req, res) => {
  const { username, bookingId, time: ampmtime, date: dateString} = req.body;

  try {
	// Fetch PlayerID.
	const playerIDcheck = await pool.query('SELECT * FROM player WHERE player_username = $1', [username]);
	const playerID = playerIDcheck.rows[0].player_id;
	
	const scriptIDcheck = await pool.query('SELECT * FROM booking WHERE booking_id = $1', [bookingId]);
    const scriptId = scriptIDcheck.rows[0].script_id;
	
	const playercountcheck = await pool.query('SELECT * FROM booking WHERE booking_id = $1', [bookingId]);
	const playercount = playercountcheck.rows[0].booking_playercount;
	
	if (playercount > 1) {
      return res.status(400).json({ message: 'Cannot alter booking with multiple participants' });
    }
	
	// Fetch available rooms.
	const availableRoomsQuery = 'SELECT room_id FROM rooms WHERE room_status = $1';
    const availableRoomsValues = ['available'];
	const availableRoomsResult = await pool.query(availableRoomsQuery, availableRoomsValues);
    const availableRoomIds = availableRoomsResult.rows.map(row => row.room_id);
	
    // Check if the booking overlaps.
    const date = new Date(dateString);
	const time = new moment(ampmtime, ['h:mm A']).format('HH:mm:ss');
    console.log('Input values:', scriptId, date, time);
	
	const bookingsResult = await pool.query('SELECT booking_id FROM booking WHERE script_id = $1 AND booking_date = $2', [scriptId, date]);
    const bookings = bookingsResult.rows.map(row => row.booking_id);
    const filteredBookingIds = bookings.filter(id => id !== parseInt(bookingId));
    const bookingQuery = `
  SELECT * FROM booking
  WHERE booking_id IN (${filteredBookingIds.map((_, i) => `$${i + 1}`).join(',')})
`;
    const bookingValues = filteredBookingIds;
    const bookingResult = await pool.query(bookingQuery, bookingValues)

    const startTimeQuery = 'SELECT booking_start FROM booking WHERE booking_id = ANY($1)';
    const startTimeResult = await pool.query(startTimeQuery, [filteredBookingIds]);
    console.log('startTimeResult:', startTimeResult.rows);

    const scriptTimeQuery = 'SELECT script_time FROM script WHERE script_id = $1';
    const scriptTimeResult = await pool.query(scriptTimeQuery, [scriptId]);
    console.log('scriptTimeResult:', scriptTimeResult.rows);
    const scriptTime = scriptTimeResult.rows[0].script_time;
    console.log('scriptTimeResult:', scriptTime);

    const endTimeQuery = 'SELECT booking_end FROM booking WHERE booking_id = ANY($1)';
    const endTimeResult = await pool.query(endTimeQuery, [filteredBookingIds]);
    console.log('endTimeResult:', endTimeResult.rows);
	
    const scriptTimeLength = scriptTimeResult.rows[0].script_time;
    const scriptHours = scriptTimeLength.hours;
    const scriptMinutes = scriptTimeLength.minutes ?? 0; 
    const scriptMilliseconds = scriptHours * 60 * 60 * 1000 + scriptMinutes * 60 * 1000;
    console.log('milliseconds:', scriptMilliseconds);

    const timeRanges = [];
    let startTime, endTime;

    for (let i = 0; i < startTimeResult.rows.length; i++) {
        const startTimeString = startTimeResult.rows[i].booking_start;
        const endTimeString = endTimeResult.rows[i].booking_end;

        startTime = new Date(`${dateString}T${startTimeString}`);
        endTime = new Date(`${dateString}T${endTimeString}`);
	
        startTime.setHours(startTime.getHours() + 8); // Adjust timezone offset here if necessary
        endTime.setHours(endTime.getHours() + 8); // Adjust timezone offset here if necessary

        const newStartTime = new Date(startTime.getTime() - scriptMilliseconds);
		console.log('Timecheck:', newStartTime, endTime);
        timeRanges.push({ startTime: newStartTime, endTime: endTime });
    }
	
	let isOverlapping = false;
	timecheck = new Date(`${dateString}T${time}`);
	timecheck.setHours(timecheck.getHours() + 8);
	console.log('Timecheck:', timecheck);

    for (let i = 0; i < timeRanges.length; i++) {
    const startTime = timeRanges[i].startTime;
    const endTime = timeRanges[i].endTime;

    if (endTime && timecheck >= startTime && timecheck < endTime) 
	{
        isOverlapping = true;
        break;
    }
}
	
	console.log('overlapCheck:', isOverlapping);
	
	if (isOverlapping) {
     return res.status(409).json({ message: 'Booking time overlaps with an existing booking' });
    }
	
	//Get booking_end
	
	startTime = new Date(`${dateString}T${time}`);
	endTime = new Date(startTime.getTime() + scriptMilliseconds);
	
    const startTimeString = startTime.toLocaleTimeString('en-US', { hour12: false });
    const endTimeString = endTime.toLocaleTimeString('en-US', { hour12: false });
	
	let assignedRoomId = null;
	console.log('available rooms:', availableRoomIds);
 for (const roomId of availableRoomIds) { // Check for time overlap with the current room
   const startTimeQuery = 'SELECT booking_start FROM booking WHERE room_id = $1 AND booking_date = $2';
        const startTimeResult = await pool.query(startTimeQuery, [roomId, date]);
        console.log('startTimeResult:', startTimeResult.rows);

        const endTimeQuery = 'SELECT booking_end FROM booking WHERE room_id = $1 AND booking_date = $2';
        const endTimeResult = await pool.query(endTimeQuery, [roomId, date]);
        console.log('endTimeResult:', endTimeResult.rows);
		
		const scriptTimeQuery = 'SELECT script_time FROM script WHERE script_id = $1';
    const scriptTimeResult = await pool.query(scriptTimeQuery, [scriptId]);
    console.log('scriptTimeResult:', scriptTimeResult.rows);
    const scriptTime = scriptTimeResult.rows[0].script_time;
    console.log('scriptTimeResult:', scriptTime);
	
	    const scriptTimeLength = scriptTimeResult.rows[0].script_time;
    const scriptHours = scriptTimeLength.hours;
    const scriptMinutes = scriptTimeLength.minutes ?? 0; 
    const scriptMilliseconds = scriptHours * 60 * 60 * 1000 + scriptMinutes * 60 * 1000;
    console.log('milliseconds:', scriptMilliseconds);
		
		let startTime, endTime;
		
		startTime = new Date(`${dateString}T${time}`);
	    endTime = new Date(startTime.getTime() + scriptMilliseconds);
		
		startTime.setHours(startTime.getHours() + 8); // Adjust timezone offset here if necessary
        endTime.setHours(endTime.getHours() + 8); 
		
		console.log('startTime:', startTime);
		console.log('endTime:', endTime);

        const timeRanges = [];

        for (let i = 0; i < startTimeResult.rows.length; i++) {
            const startTimeString = startTimeResult.rows[i].booking_start;
            const endTimeString = endTimeResult.rows[i].booking_end;
			
			console.log('Timecheck:', startTimeString, endTimeString);

            startTime = new Date(`${dateString}T${startTimeString}`);
            endTime = new Date(`${dateString}T${endTimeString}`);

            startTime.setHours(startTime.getHours() + 8); // Adjust timezone offset here if necessary
            endTime.setHours(endTime.getHours() + 8); // Adjust timezone offset here if necessary

            const newStartTime = new Date(startTime.getTime() - scriptMilliseconds);
            console.log('Timecheck:', newStartTime, endTime);
            timeRanges.push({ startTime: newStartTime, endTime: endTime });
        }

        let isOverlapping = false;
        const timecheck = startTime
        console.log('Timecheck:', timecheck);

        for (let i = 0; i < timeRanges.length; i++) {
            const startTime = timeRanges[i].startTime;
            const endTime = timeRanges[i].endTime;

            if (endTime && timecheck >= startTime && timecheck < endTime) {
                isOverlapping = true;
                break;
            }
        }

        if (!isOverlapping) {
            assignedRoomId = roomId;
			console.log('roomId:', roomId);
            break;
        }
	}

	console.log('InsertionCheck', playerID, bookingId, startTimeString, endTimeString, date, assignedRoomId);
	
	const updateQuery = `
      UPDATE booking
      SET booking_start = $1, booking_end = $2, booking_date = $3, room_id = $4
      WHERE booking_id = $5
    `;
    const updateValues = [startTimeString, endTimeString, date, assignedRoomId, bookingId];
    await pool.query(updateQuery, updateValues);

    res.status(200).json({ message: 'Booking updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Delete booking endpoint
app.post('/clear', async (req, res) => {
  const { bookingID } = req.query;

  try {
    // Delete participations related to the booking
    await pool.query('DELETE FROM participation WHERE booking_id = $1', [bookingID]);
    
    // Delete the booking itself
    await pool.query('DELETE FROM booking WHERE booking_id = $1', [bookingID]);

    res.status(200).json({ message: 'Successfully deleted booking!' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// User preference retrieval endpoint
app.get('/playerpref', async (req, res) => {
    try {
    const { username } = req.query;

    const playerResult = await pool.query('SELECT player_id FROM player WHERE player_username = $1', [username]);
    const playerId = playerResult.rows[0].player_id;

    const participationQuery = `
      SELECT booking_id
      FROM participation
      WHERE player_id = $1
    `;
    const { rows: participationRows } = await pool.query(participationQuery, [playerId]);
    const bookingIds = participationRows.map(row => row.booking_id);

     const bookingsQuery = `
      SELECT *
      FROM booking
      WHERE booking_id = ANY($1)
    `;

    const { rows: bookingRows } = await pool.query(bookingsQuery, [bookingIds]);

    const scriptIds = bookingRows.map(booking => booking.script_id);

    const scriptsQuery = `
      SELECT *
      FROM script
      WHERE script_id = ANY($1)
	  `;
    
	  const { rows: scriptRows } = await pool.query(scriptsQuery, [scriptIds]);
	  console.log('scripts:', scriptRows);

  const genreCount = new Map();
  const typeCount = new Map();
  const playermaxCount = new Map();

    scriptRows.forEach(script => {
    const { script_genre, script_type, script_playermax } = script;

    genreCount.set(script_genre, (genreCount.get(script_genre) || 0) + 1);
    typeCount.set(script_type, (typeCount.get(script_type) || 0) + 1);
    playermaxCount.set(script_playermax, (playermaxCount.get(script_playermax) || 0) + 1);
  });

  // Find the most common values
  const mostCommonGenre = [...genreCount.entries()].sort((a, b) => b[1] - a[1])[0][0];
  const mostCommonType = [...typeCount.entries()].sort((a, b) => b[1] - a[1])[0][0];
  const mostCommonPlayermax = [...playermaxCount.entries()].sort((a, b) => b[1] - a[1])[0][0];

  // Return the most common values
  res.json({ mostCommonGenre, mostCommonType, mostCommonPlayermax });
} catch (err) {
  console.error(err);
  res.status(500).json({ error: 'An error occurred while fetching data' });
}
});

//All bookings retrieval endpoint
app.get('/data', async (req, res) => {
  try {
    const query = `
      SELECT
        b.booking_id,
        b.booking_date,
        b.booking_start,
        b.booking_end,
        b.booking_state,
        b.player_id,
        b.booking_experience,
        b.booking_gender,
        b.booking_playercount,
        b.booking_malecount,
        b.booking_femalecount,
        s.script_id,
        s.script_name,
        s.script_playercount,
        s.script_time,
        s.script_playermax,
        s.script_malemax,
        s.script_femalemax,
        s.script_genre,
        s.script_type,
        s.script_contentwarning
      FROM booking b
      JOIN script s ON b.script_id = s.script_id
      WHERE b.booking_status = 'completed'
    `;

    const { rows } = await pool.query(query);

    const bookings = rows.map(row => ({
      bookingId: row.booking_id,
      bookingDate: row.booking_date,
      bookingStart: row.booking_start,
      bookingEnd: row.booking_end,
      bookingState: row.booking_state,
      playerId: row.player_id,
      bookingExperience: row.booking_experience,
      bookingGender: row.booking_gender,
      bookingPlayerCount: row.booking_playercount,
      bookingMaleCount: row.booking_malecount,
      bookingFemaleCount: row.booking_femalecount,
      scriptId: row.script_id,
      scriptName: row.script_name,
      scriptPlayerCount: row.script_playercount,
      scriptTime: row.script_time,
      scriptPlayerMax: row.script_playermax,
      scriptMaleMax: row.script_malemax,
      scriptFemaleMax: row.script_femalemax,
      scriptGenre: row.script_genre,
      scriptType: row.script_type,
      scriptContentWarning: row.script_contentwarning
    }));

    console.log(bookings); // Print the result for testing

    res.json(bookings);
  } catch (error) {
    console.error('Error retrieving bookings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

//Unassigned bookings retrieval endpoint
app.get('/unassignedbooking', async (req, res) => {
  try {
    const query = `
      SELECT
        booking.booking_id,
        script.script_name,
        script.script_playermax,
        script.script_malemax,
        script.script_femalemax,
        player.player_username,
        admin.admin_username,
        booking.booking_date,
        booking.booking_start,
        booking.booking_end,
        booking.booking_state,
        booking.player_id,
        booking.booking_experience,
        booking.booking_gender,
        booking.booking_playercount,
        booking.booking_malecount,
        booking.booking_femalecount,
        booking.admin_id
      FROM booking
      INNER JOIN script ON booking.script_id = script.script_id
      INNER JOIN player ON booking.player_id = player.player_id
      LEFT JOIN admin ON booking.admin_id = admin.admin_id
      WHERE booking.admin_id IS NULL
        AND booking.booking_status = 'pending'
    `;

    const { rows } = await pool.query(query);

    const publicBookings = rows.map(row => ({
      booking_id: row.booking_id,
      script_name: row.script_name,
      player_name: row.player_username,
      date: row.booking_date,
      start: row.booking_start,
      end: row.booking_end,
	  state: row.booking_state,
      experience: row.booking_experience,
      gender: row.booking_gender,
      playercount: row.booking_playercount,
      malecount: row.booking_malecount,
      femalecount: row.booking_femalecount,
      playermax: row.script_playermax,
      malemax: row.script_malemax,
      femalemax: row.script_femalemax,
      admin: row.admin_username
    }));

    res.json(publicBookings);
  } catch (error) {
    console.error('Error retrieving unassigned bookings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/assignedbooking', async (req, res) => {
  try {
    const { username } = req.query;

    const adminQuery = 'SELECT admin_id FROM admin WHERE admin_username = $1';
    const adminResult = await pool.query(adminQuery, [username]);

    if (adminResult.rows.length === 0) {
      return res.status(404).json({ error: 'Admin not found' });
    }

    const adminId = adminResult.rows[0].admin_id;

    const bookingQuery = `
      SELECT
        booking.booking_id,
        script.script_name,
        script.script_playermax,
        script.script_malemax,
        script.script_femalemax,
        player.player_username,
        admin.admin_username,
        booking.booking_date,
        booking.booking_start,
        booking.booking_end,
        booking.booking_state,
        booking.player_id,
        booking.booking_experience,
        booking.booking_gender,
        booking.booking_playercount,
        booking.booking_malecount,
        booking.booking_femalecount,
        booking.admin_id
      FROM booking
      INNER JOIN script ON booking.script_id = script.script_id
      INNER JOIN player ON booking.player_id = player.player_id
      LEFT JOIN admin ON booking.admin_id = admin.admin_id
      WHERE booking.admin_id = $1
        AND booking.booking_status = 'pending'
    `;

    const { rows } = await pool.query(bookingQuery, [adminId]);

    const assignedBookings = rows.map(row => ({
      booking_id: row.booking_id,
      script_name: row.script_name,
      player_name: row.player_username,
      date: row.booking_date,
      start: row.booking_start,
      end: row.booking_end,
	  state: row.booking_state,
      experience: row.booking_experience,
      gender: row.booking_gender,
      playercount: row.booking_playercount,
      malecount: row.booking_malecount,
      femalecount: row.booking_femalecount,
      playermax: row.script_playermax,
      malemax: row.script_malemax,
      femalemax: row.script_femalemax,
      admin: row.admin_username
    }));

    res.json(assignedBookings);
  } catch (error) {
    console.error('Error retrieving assigned bookings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/assign', async (req, res) => {
  const { username, bookingID } = req.query;

  try {
    const adminIDResult = await pool.query('SELECT admin_id FROM admin WHERE admin_username = $1', [username]);
    const adminID = adminIDResult.rows[0].admin_id;
    const existingBookings = await pool.query('SELECT * FROM booking WHERE admin_id = $1 AND booking_status = $2', [adminID, 'pending']);
    
    const timeRanges = existingBookings.rows.map(booking => ({
      date: new Date(booking.booking_date),
      startTime: booking.booking_start,
      endTime: booking.booking_end
    }));

    console.log('Admin ID:', adminID);
    console.log('Existing Bookings:', existingBookings.rows);
    console.log('Time Ranges:', timeRanges);

    const bookingResult = await pool.query('SELECT * FROM booking WHERE booking_id = $1', [bookingID]);
    if (bookingResult.rows.length === 0) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    const newBookingDate = new Date(bookingResult.rows[0].booking_date);
    const newBookingStartTime = bookingResult.rows[0].booking_start;
    const newBookingEndTime = bookingResult.rows[0].booking_end;

    console.log('New Booking Date:', newBookingDate);
    console.log('New Booking Start Time:', newBookingStartTime);
    console.log('New Booking End Time:', newBookingEndTime);

    let isOverlapping = false;
    for (let i = 0; i < timeRanges.length; i++) {
      const { date, startTime, endTime } = timeRanges[i];
      if (newBookingDate.getTime() === date.getTime()) { 
        if (
          (newBookingStartTime >= startTime && newBookingStartTime < endTime) ||
          (newBookingEndTime > startTime && newBookingEndTime <= endTime) ||
          (newBookingStartTime <= startTime && newBookingEndTime >= endTime)
        ) {
          isOverlapping = true;
          break;
        }
      }
    }

    if (isOverlapping) {
      return res.status(409).json({ message: 'Booking time overlaps with an existing booking' });
    }

    const updateQuery = `
      UPDATE booking
      SET admin_id = $1
      WHERE booking_id = $2
    `;
    const updateValues = [adminID, bookingID];
    await pool.query(updateQuery, updateValues);

    res.status(200).json({ message: 'Successfully assigned booking to admin!' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.post('/markComplete', async (req, res) => {
  const { bookingID } = req.query;

  try {
	console.log('Booking ID:', bookingID);
	
    const updateQuery = `
      UPDATE booking
      SET booking_status = $1
      WHERE booking_id = $2
    `;
    const updateValues = ['completed', bookingID];
    await pool.query(updateQuery, updateValues);
	
    res.status(200).json({ message: 'Booking marked as completed' });
  } catch (error) {
    console.error('Error marking booking as completed:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.post('/markCancelled', async (req, res) => {
  const { bookingID } = req.query;

  try {
	console.log('Booking ID:', bookingID);
	
    const updateQuery = `
      UPDATE booking
      SET booking_status = $1
      WHERE booking_id = $2
    `;
    const updateValues = ['cancelled', bookingID];
    await pool.query(updateQuery, updateValues);
    
    res.status(200).json({ message: 'Booking marked as cancelled' });
  } catch (error) {
    console.error('Error marking booking as cancelled:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.get('/fetchroomlength', async (req, res) => {
  try {
    const countQuery = `
      SELECT COUNT(*) AS roomCount
      FROM rooms
      WHERE room_status = 'available'
    `;
    const countResult = await pool.query(countQuery);
    const roomCount = parseInt(countResult.rows[0].roomcount, 10);
    res.status(200).json({ roomCount: roomCount });
  } catch (error) {
    console.error('Error fetching room count:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.get('/getreviews', async (req, res) => {
  const { script_id } = req.query;

  try {
    const query = `
      SELECT
        review.review_id,
        player.player_username,
        review.review_rating,
        review.review_contents,
        review.script_id
      FROM review
      INNER JOIN player ON review.player_id = player.player_id
      WHERE review.script_id = $1
    `;

    const { rows } = await pool.query(query, [script_id]);

    const reviews = rows.map(row => ({
      review_id: row.review_id,
      review_owner: row.player_username,
      review_rating: row.review_rating,
      review_contents: row.review_contents,
      script_id: row.script_id,
    }));

    res.json(reviews);
  } catch (error) {
    console.error('Error retrieving reviews:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/postreview', async (req, res) => {
  const { username, booking_id, rating, contents } = req.body;

  try {
	  
	  const playerQuery = `
      SELECT player_id
      FROM player
      WHERE player_username = $1
    `;
    const playerResult = await pool.query(playerQuery, [username]);
    const player_id = playerResult.rows[0].player_id;

    const scriptQuery = `
      SELECT script_id
      FROM booking
      WHERE booking_id = $1
    `;
    const scriptResult = await pool.query(scriptQuery, [booking_id]);
    const scriptId = scriptResult.rows[0].script_id;

    const query = `
      INSERT INTO review (player_id, review_rating, review_contents, script_id)
      VALUES ($1, $2, $3, $4)
      RETURNING review_id
    `;
    const { rows } = await pool.query(query, [player_id, rating, contents, scriptId]);
	
	// Update booking_reviewed status to true
    const updateBookingQuery = `
      UPDATE booking
      SET booking_reviewed = true
      WHERE booking_id = $1
    `;
    await pool.query(updateBookingQuery, [booking_id]);
	
    const reviewId = rows[0].review_id;

    res.status(201).json({ review_id: reviewId });
  } catch (error) {
    console.error('Error adding review:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/getprofile', async (req, res) => {
  const { username } = req.query;

  try {
    const query = `
      SELECT
        player_id,
        player_username,
        player_email,
        player_gender,
        player_playedcases
      FROM player
      WHERE player_username = $1
    `;
    const { rows } = await pool.query(query, [username]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const profile = rows[0];
    res.json({
      player_id: profile.player_id,
      player_username: profile.player_username,
      player_email: profile.player_email,
      player_gender: profile.player_gender,
      player_playedcases: profile.player_playedcases,
    });
  } catch (error) {
    console.error('Error retrieving profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/updateProfile', async (req, res) => {
  const { oldUsername, newUsername, newEmail } = req.body;
  console.log('profileinfo:', oldUsername, newUsername, newEmail);
  if (!oldUsername || !newUsername || !newEmail) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    const checkQuery = `
      SELECT COUNT(*) AS count
      FROM player
      WHERE player_username = $1 OR player_email = $2
    `;
    const checkValues = [newUsername, newEmail];
    const checkResult = await pool.query(checkQuery, checkValues);

    if (checkResult.rows[0].count > 0) {
      return res.status(400).json({ error: 'Username or email already exists' });
    }

    const updateQuery = `
      UPDATE player
      SET player_username = $1,
          player_email = $2
      WHERE player_username = $3
    `;
    const updateValues = [newUsername, newEmail, oldUsername];

    const result = await pool.query(updateQuery, updateValues);
    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Old username not found' });
    }
    res.status(200).json({ message: 'Profile updated successfully' });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});


// Start the server
app.listen(3000, () => {
  console.log('Server is running on port 3000');
});