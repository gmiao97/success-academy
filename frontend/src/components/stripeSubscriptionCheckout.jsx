import React, { useState, useEffect } from 'react';
import { makeStyles } from '@material-ui/core/styles';
import { CardElement } from '@stripe/react-stripe-js';
import { green } from '@material-ui/core/colors';
import { Check } from '@material-ui/icons';
import { 
  Typography,
  Button,
  Radio,
  RadioGroup,
  FormControlLabel,
  FormControl,
  FormLabel,
  CircularProgress,
  Grid,
  Box,
  TextField,
  Link as MaterialLink,
  Checkbox,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Card,
  CardContent,
} from '@material-ui/core';

import axiosInstance from '../axiosApi';
import { userAgreement } from '../util';


const useStyles = makeStyles(theme => ({
  sectionEnd: {
    marginBottom: theme.spacing(2),
  },
  cardSection: {
    maxWidth: 500,
    margin: 'auto',
  },
  strikethrough: {
    textDecoration: 'line-through',
  },
}));

const CARD_ELEMENT_OPTIONS = {
  style: {
    base: {
      color: "#32325d",
      fontFamily: 'Meiryo, Hiragino Mincho',
      fontSmoothing: "antialiased",
      fontSize: "16px",
      "::placeholder": {
        color: "#aab7c4",
      },
    },
    invalid: {
      color: "#fa755a",
      iconColor: "#fa755a",
    },
  },
};

export default function StripeSubscriptionCheckout(props) {
  const classes = useStyles();
  const [priceList, setPriceList] = useState(null);
  const [cardInputError, setCardInputError] = useState('');
  const [code, setCode] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);


  useEffect(() => {
    getPlans();
  }, []);

  const getPlans = async () => {
    try {
      const priceResponse = await axiosInstance.get('/yoyaku/stripe-prices/');
      setPriceList(priceResponse.data.data.sort((a, b) => {
        return a.product.name.length - b.product.name.length;
      }));
      props.setSelectedPrice(priceResponse.data.data[0].id);
    } catch(err) {
      console.error(err.stack);
      props.setError('サブスクリプションプランを読み込みできませんでした。');
      props.setErrorSnackbarOpen(true);
    }
  }

  const handleChange = (event) => {
    setCardInputError('');
    if (event.complete) {
      props.setCardEntered(true);
      setCardInputError('');
    } else if (event.error) {
      props.setCardEntered(false);
      setCardInputError(event.error.message);
    }
  }

  const preschoolPriceDisabled = (productName) => {
    const classCodes = ['ENBE１', 'HNPNEE１', 'HEPE１', 'HNPNEE２', 'HNPNEE３', 'ENBE1', 'HNPNEE1', 'HEPE1', 'HNPNEE2', 'HNPNEE3'];
    return productName.includes('未就学児') && !classCodes.includes(code);
  }

  return (
    <div id='stripeSubscriptionCheckout' className={classes.sectionEnd}>
      {priceList === null ? 
        <Grid container justify='center'>
          <CircularProgress color="primary" />
        </Grid> :
        <div>
          <FormControl component='fieldset'>
            <FormLabel component='legend'>プランを選択して下さい</FormLabel>
            <RadioGroup id='selectedPrice' name="selectedPrice" value={props.selectedPrice} onChange={e => props.setSelectedPrice(e.target.value)}>
              {priceList.map(price => 
                <FormControlLabel 
                  key={price.id}
                  value={price.id} 
                  control={<Radio />} 
                  label={
                    <div>
                      <Typography color='textPrimary'>{price.product.name}</Typography>
                      <Typography variant='caption' color='textSecondary'>{price.nickname}</Typography>
                    </div>
                  }
                  disabled={preschoolPriceDisabled(price.product.name)}
                />
              )}
            </RadioGroup>
          </FormControl> 
          <TextField id='code' name='code' className={classes.sectionEnd} type='text' label='クラス番号' helperText='未就学児クラスのみ' value={code} 
          onChange={e => setCode(e.target.value)} fullWidth variant='outlined' size='small' />
          <Grid id='legalSection' container justify='flex-start' spacing={1}>

            <Grid item>
              <MaterialLink 
                href='http://mercy-education.com/FREE/cn2/2020-07-14-3.html'
                target='_blank'
                rel='noopener noreferrer'
                color='secondary'
              >
                プランのご説明
              </MaterialLink>
            </Grid>
            <Grid item>
              <MaterialLink 
                href='http://mercy-education.com/FREE/cn2/2020-08-18.html'
                target='_blank'
                rel='noopener noreferrer'
                color='secondary'
              >
                お支払いのご案内
              </MaterialLink>
            </Grid>

            <Grid item xs={12}>
              <Button variant='outlined' color='secondary' size='small' onClick={() => setDialogOpen(true)}>
                利用規約
              </Button>
              <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)}>
                <DialogTitle>サクセス・アカデミー利用規約</DialogTitle>
                <DialogContent>
                  <DialogContentText>
                    {userAgreement.map(line =>
                      <Typography>
                        {line}
                      </Typography>
                    )}
                  </DialogContentText>
                </DialogContent>
              </Dialog>
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                value="end"
                control={<Checkbox color="primary" checked={props.agreed} onChange={e => props.setAgreed(e.target.checked)} color='secondary' />}
                label="利用規約に同意します"
                labelPlacement="end"
              />
            </Grid>
          </Grid>
          <Grid id='cardSection' container justify='center' spacing={1}>
            <Grid item xs={12}>
              <CardElement className={classes.cardSection} options={CARD_ELEMENT_OPTIONS} onChange={handleChange} />
            </Grid>
            <Grid item xs={12}>
              <Typography variant='caption' color='error' display='block' align='center'>{cardInputError}</Typography>
            </Grid>
          </Grid>
          <Card variant='outlined'>
            <CardContent>
              <Typography color='textPrimary' variant='body1' display='block' gutterBottom>
                30日の無料トライアル期間後の一回目の請求は以下の通り
              </Typography>
              <Typography color='textSecondary' variant='body2' display='inline' className={props.isReferral ? classes.strikethrough : null}>
                入会費：＄100
              </Typography>
              {props.isReferral ?
                <Typography color='textSecondary' variant='caption' display='inline'>
                  <Check color='secondary' fontSize='small' style={{ color: green[500] }} />
                  紹介で免除
                </Typography> :
                null
              }
              <Typography color='textSecondary' variant='body2' gutterBottom>
                選択されたプランの月額
              </Typography>
              <Typography color='textPrimary' variant='body1' display='block'>
                それから毎月選択されたプランの月額を請求させていただきます
              </Typography>
            </CardContent>
          </Card>
        </div>
      }
    </div>
  );
}


