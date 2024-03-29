import React, { useState, useEffect } from 'react';
import moment from 'moment-timezone';
import { styled, makeStyles } from '@material-ui/core/styles';
import { KeyboardDatePicker } from '@material-ui/pickers';
import { LocationOn } from '@material-ui/icons';
import { Alert, Autocomplete } from '@material-ui/lab'
import {  
  Typography,
  Button,
  Grid,
  Snackbar,
  Divider,
  TextField,
  ButtonGroup,
  IconButton,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
} from '@material-ui/core';

import { MyAvatar } from '../home';
import axiosInstance from '../../../axiosApi';
import { gradeMappings, timeZoneNames, getUserIdFromToken, avatarMapping, referralMessage } from '../../../util';
import ChangePassword from './changePassword';


const MyGrid = styled(Grid)({
  alignItems: 'flex-start',
});

const useStyles = makeStyles(theme => ({
  sectionEnd: {
    marginBottom: theme.spacing(2),
  },
  backButton: {
    marginRight: theme.spacing(1),
  },
  multiline: {
    whiteSpace: 'pre-line',
  },
}));


export function Subscription(props) {
  const subscriptionStatusMap = new Map([
    ['active', '有効'],
    ['past_due', 'インボイス期日経過'],
    ['unpaid', '未払い'],
    ['canceled', 'キャンセル'],
    ['incomplete', '登録未完了'],
    ['incomplete_expired', '登録無効'],
    ['trialing', 'トライアル期間中'],
  ]);

  const handleStripeCustomerPortalRedirect = async () => {
    const response = await axiosInstance.post('/yoyaku/stripe-customer-portal/', {
      customerId: props.stripeCustomerId,
    });
    console.log(response.data.url);
    window.location.assign(response.data.url);
  }

  if (!props.currentUser.stripeSubscriptionProvision) {
    return(
      <div>
        <Typography variant='h6' color='textSecondary' display='block' gutterBottom>
          サブスクリプションがありません（月会費を払っていません）
        </Typography>
        <Button variant='contained' color='secondary' type='button' onClick={handleStripeCustomerPortalRedirect}>
          プランと支払い方法の管理
        </Button>
      </div>
    );
  }

  return(
    <div>
      <Typography variant='h6' color='textSecondary' display='block' gutterBottom>
        現在のプラン・
        <Typography color='secondary' display='inline'>{props.currentProduct.name}</Typography>
      </Typography>
      <Typography variant='h6' color='textSecondary' display='block' gutterBottom>
        ステータス・
        <Typography color='secondary' display='inline'>{subscriptionStatusMap.get(props.currentSubscription.status)}</Typography>
      </Typography>
      <Typography variant='h6' color='textSecondary' display='block' gutterBottom>
        値段・
        <Typography color='secondary' display='inline'>{props.currentSubscription.items.data[0].price.nickname}</Typography>
      </Typography>
      <Button variant='contained' color='secondary' type='button' onClick={handleStripeCustomerPortalRedirect}>
        プランと支払い方法の管理
      </Button>
      <Snackbar open={props.currentSubscription.status === 'trialing'}>
        <Alert severity='warning' variant='filled'>
          トライアル期間中にプランを変更するとすぐに支払いが始まりますのでご注意下さい
        </Alert>
      </Snackbar>
    </div>
  );
}

export default function StudentProfile(props) {
  const classes = useStyles();
  const [edit, setEdit] = useState(false);
  const [avatarDialogOpen, setAvatarDialogOpen] = useState(false);
  const [referralDialogOpen, setReferralDialogOpen] = useState(false);
  const [changePassword, setChangePassword] = useState(false);
  const [dateError, setDateError] = useState(false);
  const [usernameList, setUsernameList] = useState([]);
  const [preschoolInfo, setPreschoolInfo] = useState('');
  const [editForm, setEditForm] = useState({
    username: props.currentUser.username,
    email: props.currentUser.email,
    first_name: props.currentUser.first_name,
    last_name: props.currentUser.last_name,
    description: props.currentUser.description,
    avatar: props.currentUser.avatar,
    time_zone: props.currentUser.time_zone.replace('_', ' '), 
    phone_number: props.currentUser.phone_number, 
    birthday: props.currentUser.birthday,
    student_profile: {
      school_name: props.currentUser.student_profile.school_name,
      school_grade: props.currentUser.student_profile.school_grade,
    },
    student_id: props.currentUser.student_profile.id,
  });
  const schoolGrades = Array.from(gradeMappings.entries());
  const avatars = Array.from(avatarMapping.keys());

  useEffect(() => {
    getPreschoolInfo();
  }, []);

  useEffect(() => {
    getUsernameList();
  }, [editForm.username]);

  const getUsernameList = async () => {
    const response = await axiosInstance.get('/yoyaku/users/username_list/');
    setUsernameList(response.data);
  }

  const getPreschoolInfo = async () => {
    const response = await axiosInstance.get(`/yoyaku/preschool-info/${props.currentUser.student_profile.preschool}/`);
    setPreschoolInfo(response.data.name);
  }

  const usernameTaken = () => usernameList.includes(editForm.username) && editForm.username !== props.currentUser.username;

  const handleChange = event => {
    setEditForm({
      ...editForm,
      [event.target.name]: event.target.value,
    });
  }

  const handleChangeStudentProfile = event => {
    setEditForm({
      ...editForm,
      student_profile: {
        ...editForm.student_profile,
        [event.target.name]: event.target.value,
      },
    });
  }

  const handleDateChange = (name, date) => {
    setEditForm({
      ...editForm,
      [name]: moment(date).format('YYYY-MM-DD'),
    });
    setDateError(!date || !date.isValid());
  }

  const resetEditForm = () => {
    setEditForm({
      username: props.currentUser.username,
      email: props.currentUser.email,
      first_name: props.currentUser.first_name,
      last_name: props.currentUser.last_name, 
      description: props.currentUser.description,
      avatar: props.currentUser.avatar,
      time_zone: props.currentUser.time_zone.replace('_', ' '), 
      phone_number: props.currentUser.phone_number, 
      birthday: props.currentUser.birthday,
      student_profile: {
        school_name: props.currentUser.student_profile.school_name,
        school_grade: props.currentUser.student_profile.school_grade,
      },
      student_id: props.currentUser.student_profile.id,
    });
  }

  const handleSubmit = async (event) => {
    event.preventDefault();
    const response = await axiosInstance.patch(`/yoyaku/users/${getUserIdFromToken()}/`, {
      ...editForm,
      time_zone: editForm.time_zone.replace(' ', '_'),
    });
    props.setReload(true);
    setEdit(false);
    props.setSuccessMessage('プロフィールを編集されました。')
    props.setSuccessSnackbarOpen(true);
  }

  if (changePassword) {
    return(
      <ChangePassword 
        setChangePassword={setChangePassword}
        setSuccessMessage={props.setSuccessMessage}
        setSuccessSnackbarOpen={props.setSuccessSnackbarOpen}
      />
    );
  }

  if (edit) {
    return(
      <form id='editStudentProfile' onSubmit={handleSubmit}>
        <MyGrid container spacing={3} className={classes.sectionEnd}>
          <MyGrid item xs={12}>
            <IconButton onClick={() => setAvatarDialogOpen(true)}>
              <MyAvatar avatar={editForm.avatar} initial={props.currentUser.last_name[0].toUpperCase()} />
            </IconButton>
          </MyGrid>
          <MyGrid item xs={12}>
            <TextField id='username' name='username' type='text' label='ユーザー名' value={editForm.username} onChange={handleChange} required fullWidth variant='filled'
            error={usernameTaken()} helperText={usernameTaken() ? 'そのユーザー名はすでに使われています' : '半角英数・記号'} />
          </MyGrid>
          <MyGrid item xs={12} sm={6}>
            <TextField id='last_name' name='last_name' type='text' label='生徒姓' value={editForm.last_name} onChange={handleChange} required fullWidth />
          </MyGrid>
          <MyGrid item xs={12} sm={6}>
            <TextField id='first_name' name='first_name' type='text' label='生徒名' value={editForm.first_name} onChange={handleChange} required fullWidth />
          </MyGrid>
          <MyGrid item xs={12}>
            <TextField id='description' name='description' type='text' label='自己紹介' value={editForm.description} onChange={handleChange} variant='outlined' 
            inputProps={{maxLength: 255}} helperText='300文字数制限' multiline fullWidth />
          </MyGrid>
          <MyGrid item xs={12} sm={5}>
            <TextField id='school_name' name='school_name' type='text' label='生徒学校名' value={editForm.student_profile.school_name} onChange={handleChangeStudentProfile} required fullWidth />
          </MyGrid>
          <MyGrid item xs={6} sm={3}>
            <Autocomplete
              id='school_grade'
              name='school_grade'
              options={schoolGrades}
              getOptionLabel={option => option[1]}
              getOptionSelected={(option, value) => option[1] === value[1]}
              value={[editForm.student_profile.school_grade, gradeMappings.get(editForm.student_profile.school_grade)]}
              onChange={(event, value) => {
                setEditForm({
                  ...editForm,
                  student_profile: {
                    ...editForm.student_profile,
                    school_grade: value[0],
                  },
                });
              }}
              renderInput={(params) => <TextField {...params} label="生徒学年" />}
              disableClearable
            />
          </MyGrid>
          <MyGrid item xs={6} sm={4}>
            <KeyboardDatePicker
              id='birthday'
              name='birthday'
              variant='inline'
              label="生徒生年月日"
              value={editForm.birthday}
              onChange={date => handleDateChange('birthday', date)}
              format='YYYY-MM-DD'
              invalidDateMessage='正しい日にちを入力して下さい'
              maxDateMessage='正しい日にちを入力して下さい'
              minDateMessage='正しい日にちを入力して下さい'
            />
          </MyGrid>
          <MyGrid item xs={12} sm={6}>
            <TextField id='email' name='email' type='email' label='保護者メールアド' value={editForm.email} onChange={handleChange} required fullWidth />
          </MyGrid>
          <MyGrid item xs={12} sm={6}>
            <TextField id='phone_number' name='phone_number' type='text' label='保護者電話番号' value={editForm.phone_number} onChange={handleChange} required fullWidth />
          </MyGrid>
          <MyGrid item xs={12} sm={6}>
            <Autocomplete
              id='time_zone'
              name='time_zone'
              options={timeZoneNames}
              value={editForm.time_zone}
              onChange={(event, value) => {
                setEditForm({
                  ...editForm,
                  time_zone: value,
                });
              }}
              renderInput={(params) => <TextField {...params} label="地域/タイムゾーン" />}
              disableClearable
            />
          </MyGrid>
        </MyGrid>
        <Button type='button' onClick={() => {setEdit(false)}} className={classes.backButton}>
          戻る
        </Button>
        <Button type='submit' variant='contained' color='primary' disabled={dateError || usernameTaken()}>
          提出
        </Button>

        <Dialog open={avatarDialogOpen} onClose={() => setAvatarDialogOpen(false)}>
          <DialogTitle>アバターを選択</DialogTitle>
          <DialogContent>
            {avatars.map(avatar => 
              <IconButton 
                onClick={() => {
                  setEditForm({...editForm, avatar: avatar});
                  setAvatarDialogOpen(false);
                }}
                key={avatar}
              >
                <MyAvatar avatar={avatar} />
              </IconButton>
            )}
            <IconButton onClick={() => {
              setEditForm({...editForm, avatar: ''});
              setAvatarDialogOpen(false);
            }}>
              <MyAvatar initial={props.currentUser.last_name[0].toUpperCase()} />
            </IconButton>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setAvatarDialogOpen(false)} color="primary">
              キャンセル
            </Button>
          </DialogActions>
        </Dialog>
      </form>
    );
  }

  return(
    <div>
      <Grid container justify='space-between'>
        <Grid container justify='space-between' spacing={2}>
          <Grid item>
            <MyAvatar avatar={props.currentUser.avatar} initial={props.currentUser.last_name[0].toUpperCase()} />
          </Grid>
          <Grid item>
            <ButtonGroup variant="text" color="primary">
              <Button 
                type="button" 
                size='small' 
                color='primary' 
                onClick={() => {
                  setEdit(true);
                  resetEditForm();
                }}
              >
                プロフィール編集
              </Button>
              <Button type="button" size='small' color='primary' onClick={() => setChangePassword(true)}>
                パスワード変更
              </Button>
            </ButtonGroup>
          </Grid>
        </Grid>
        <Typography variant='h5' color='textSecondary' display='block' gutterBottom>
          {`${props.currentUser.last_name} ${props.currentUser.first_name}様`}
          <Typography variant='caption' color='secondary' display='inline'>
            ・生徒
          </Typography>
        </Typography>
        <Typography variant='caption' color='secondary' display='inline'>
          <LocationOn /> {props.currentUser.time_zone.replace('_', ' ')}
        </Typography>
      </Grid>
      <Button size='small' color='secondary' variant='contained' className={classes.sectionEnd} onClick={() => setReferralDialogOpen(true)}>
        紹介コードを見る
      </Button>
      <Typography variant='subtitle2' color='textSecondary' display='block' gutterBottom>
        ユーザー名・
        <Typography variant='body2' color='textPrimary' display='inline'>
          {props.currentUser.username}
        </Typography>
      </Typography>
      <Typography variant='subtitle2' color='textSecondary' display='block' gutterBottom>
        生年月日・
        <Typography variant='body2' color='textPrimary' display='inline'>
          {props.currentUser.birthday}
        </Typography>
      </Typography>
      <Typography variant='subtitle2' color='textSecondary' display='block' gutterBottom>
        紹介者・
        <Typography variant='body2' color='textPrimary' display='inline'>
          {props.currentUser.student_profile.referrer}
        </Typography>
      </Typography>
      <Typography variant='subtitle2' color='textSecondary' display='block' gutterBottom>
        学校名・
        <Typography variant='body2' color='textPrimary' display='inline'>
          {props.currentUser.student_profile.school_name}
        </Typography>
      </Typography>
      <Typography variant='subtitle2' color='textSecondary' display='block' gutterBottom>
        学年・
        <Typography variant='body2' color='textPrimary' display='inline'>
          {gradeMappings.get(props.currentUser.student_profile.school_grade)}
        </Typography>
      </Typography>
      {props.currentUser.student_profile.preschool ? 
        <Typography variant='subtitle2' color='textSecondary' display='block' gutterBottom>
          未就学児クラス・
          <Typography variant='body2' color='textPrimary' display='inline'>
            {preschoolInfo}
          </Typography>
        </Typography> :
        null
      }
      <Divider />
      <Typography variant='subtitle1' color='textSecondary' display='block' gutterBottom>
        自己紹介
      </Typography>
      <Typography variant='body2' color='textPrimary' display='block' className={classes.multiline} gutterBottom>
        {props.currentUser.description}
      </Typography>
      <Divider />
      <Typography variant='subtitle1' color='textSecondary' display='block' gutterBottom>
        連絡情報
      </Typography>
      <Typography variant='subtitle2' color='textSecondary' display='block' gutterBottom>
        保護者メールアドレス・
        <Typography variant='body2' color='textPrimary' display='inline'>
          {props.currentUser.email}
        </Typography>
      </Typography>
      <Typography variant='subtitle2' color='textSecondary' display='block' gutterBottom>
        保護者電話番号・
        <Typography variant='body2' color='textPrimary' display='inline'>
          {props.currentUser.phone_number}
        </Typography>
      </Typography>

      <Dialog open={referralDialogOpen} onClose={() => setReferralDialogOpen(false)}>
        <DialogTitle>紹介コード（以下の文章をコピペしてシェアしてください！）</DialogTitle>
        <DialogContent>
          <Typography>
            →紹介コード『<Typography display='inline' color='secondary'>{props.currentUser.referral_code}</Typography>』
          </Typography>
          {referralMessage.map((line, index) => 
            <Typography key={index}>
              {line}
            </Typography>  
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}